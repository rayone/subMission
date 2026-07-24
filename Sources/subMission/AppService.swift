import AppKit
import os.log
import TransmissionRPC

// MARK: - ObserverToken

final class ObserverToken: Equatable {
    let id = UUID()
    weak var service: AppService?

    init(service: AppService) {
        self.service = service
    }

    deinit {
        let tokenID = id
        let svc = service
        Task { @MainActor in
            svc?.removeObserver(by: tokenID)
        }
    }

    func cancel() {
        let tokenID = id
        let svc = service
        Task { @MainActor in
            svc?.removeObserver(by: tokenID)
        }
    }

    static func == (lhs: ObserverToken, rhs: ObserverToken) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - ServiceEvent

enum ServiceEvent {
    case torrentsUpdated(TableChangeset)
    case sessionUpdated
    case statsUpdated
    case selectionChanged
    case freeSpaceUpdated
    case connectionStateChanged
}

// MARK: - AppService

@MainActor
final class AppService {
    private let log = Logger(subsystem: "subMission", category: "portSync")
    // MARK: State
    private(set) var torrents: [Torrent] = []
    private(set) var session: Session?
    private(set) var sessionStats: SessionStats?
    private(set) var selectedIDs: Set<Int> = []
    private(set) var filteredTorrents: [Torrent] = []
    private(set) var allLabels: [String] = []
    private(set) var freeSpace: Int64 = 0
    private(set) var connectionState: ConnectionState = .connecting
    private(set) var lastPortSyncResult: String = ""
    private(set) var isMutating: Bool = false
    private let filterService = TorrentFilterService()
    var filterState: FilterState {
        get { filterService.state }
        set {
            filterService.state = newValue
            recomputeFilteredTorrents()
            notify(.torrentsUpdated(.empty))   // instant UI refresh
        }
    }

    // Speed history (last 60 samples)
    private(set) var speedHistory: [(dl: Int64, ul: Int64)] = []
    private let maxHistorySamples = 60

    // MARK: Internals
    private(set) var rpcSession: RPCSession?
    private(set) var connectionHost: String = ""
    private(set) var connectionPort: Int = 0
    private lazy var pollingCoordinator = PollingCoordinator(service: self)
    private var portPollTask: Task<Void, Never>?
    private var observers: [(id: UUID, block: (ServiceEvent) -> Void)] = []
    private let portFetcher = PortFetcher()

    // MARK: - Configuration

    func configure(host: String, port: Int, path: String, useHTTPS: Bool,
                   username: String?, password: String?) {
        let transport = HTTPTransport(
            host: host, port: port, path: path, useHTTPS: useHTTPS,
            username: username, password: password
        )
        rpcSession = RPCSession(transport: transport)
        connectionHost = host
        connectionPort = port
        connectionState = .connecting
        notify(.connectionStateChanged)
    }

    // MARK: - Observer Pattern

    func addObserver(_ block: @escaping (ServiceEvent) -> Void) -> ObserverToken {
        let token = ObserverToken(service: self)
        observers.append((id: token.id, block: block))
        return token
    }

    func removeObserver(by id: UUID) {
        observers.removeAll { $0.id == id }
    }

    private func notify(_ event: ServiceEvent) {
        for obs in observers { obs.block(event) }
    }

    // MARK: - Polling

    func startPolling(interval: Duration = .seconds(2)) {
        pollingCoordinator.startPolling(interval: interval)
    }

    func stopPolling() {
        pollingCoordinator.stopPolling()
        portPollTask?.cancel()
        portPollTask = nil
    }

    /// Called when URL is saved in settings — fires a one-shot fetch (no loop).
    func restartPortPoll() {
        portPollTask?.cancel()
        portPollTask = nil
        let urlString = ServerConfig.load().portPollURL
        guard !urlString.isEmpty else { return }
        portPollTask = Task { [weak self] in
            _ = await self?.syncPortFromURL(urlString)
        }
    }

    /// Fetch port from URL and push to Transmission if it differs.
    /// Returns a user-facing status string; also stored in lastPortSyncResult.
    @discardableResult
    func syncPortFromURL(_ urlString: String) async -> String {
        guard !urlString.isEmpty else { return "" }
        log.info("syncPort: fetching from \(urlString)")

        guard let port = await portFetcher.fetchPort(from: urlString) else {
            let msg = S.PortSync.fetchFailed
            log.error("syncPort: fetch failed")
            lastPortSyncResult = msg; return msg
        }
        log.info("syncPort: got port \(port)")

        guard let rpc = rpcSession else {
            let msg = S.PortSync.notConnected(port: port)
            log.error("syncPort: no rpc session")
            lastPortSyncResult = msg; return msg
        }

        if let current = session?.peerPort, port == current {
            let msg = S.PortSync.alreadyInSync(port: port)
            log.info("syncPort: already in sync (\(port))")
            lastPortSyncResult = msg; return msg
        }
        log.info("syncPort: current=\(self.session?.peerPort ?? -1), pushing \(port)")

        var patch = SessionPatch()
        patch.peerPort = port
        do {
            try await rpc.setSession(patch)
            await refresh()
            let msg = S.PortSync.updated(port: port)
            log.info("syncPort: success → \(port)")
            lastPortSyncResult = msg; return msg
        } catch {
            let msg = S.PortSync.updateFailed(reason: error.localizedDescription)
            log.error("syncPort: setSession failed: \(error.localizedDescription)")
            lastPortSyncResult = msg; return msg
        }
    }

    // MARK: - Refresh

    func refresh() async {
        guard let session = rpcSession else { return }
        do {
            async let torrentsFetch = session.fetchTorrents()
            async let sessionFetch = session.fetchSession()
            async let statsFetch = session.fetchStats()

            let (newTorrents, newSession, newStats) = try await (torrentsFetch, sessionFetch, statsFetch)

            let changeset = computeChangeset(old: torrents, new: newTorrents)
            torrents = newTorrents
            self.session = newSession
            self.sessionStats = newStats
            
            if connectionState != .connected {
                connectionState = .connected
                notify(.connectionStateChanged)
                // First connect: sync peer port from URL if configured
                let portURL = ServerConfig.load().portPollURL
                if !portURL.isEmpty {
                    Task { [weak self] in _ = await self?.syncPortFromURL(portURL) }
                }
            }

            let dlSpeed = newStats.downloadSpeed
            let ulSpeed = newStats.uploadSpeed
            speedHistory.append((dl: dlSpeed, ul: ulSpeed))
            if speedHistory.count > maxHistorySamples {
                speedHistory.removeFirst(speedHistory.count - maxHistorySamples)
            }

            let newLabels = Set(newTorrents.flatMap { $0.labels })
            allLabels = newLabels.sorted()

            recomputeFilteredTorrents()
            notify(.torrentsUpdated(changeset))
            notify(.sessionUpdated)
            notify(.statsUpdated)

        } catch {
            let newState: ConnectionState = .error(error.localizedDescription)
            if connectionState != newState {
                connectionState = newState
                notify(.connectionStateChanged)
            }
        }
    }

    func refreshFreeSpace() async {
        guard let rpcSession, let downloadDir = session?.downloadDir, !downloadDir.isEmpty else { return }
        do {
            let result = try await rpcSession.freeSpace(path: downloadDir)
            freeSpace = result.sizeBytes
            notify(.freeSpaceUpdated)
        } catch {
        }
    }

    // MARK: - Mutating
    
    func setMutating(_ mutating: Bool) {
        isMutating = mutating
    }
    
    // MARK: - Selection

    func setSelection(_ ids: Set<Int>) {
        guard ids != selectedIDs else { return }
        selectedIDs = ids
        notify(.selectionChanged)
    }

    var selectedTorrents: [Torrent] {
        torrents.filter { selectedIDs.contains($0.id) }
    }

    private func recomputeFilteredTorrents() {
        filteredTorrents = filterService.apply(to: torrents)
    }
}
