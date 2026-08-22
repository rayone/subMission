import AppKit
import TransmissionRPC

final class StatusFooterView: NSView {
    private let appService: AppService
    private let connectionLabel   = NSTextField(labelWithString: "🟡 …")
    private let torrentCountLabel = NSTextField(labelWithString: "—")
    private let dlSpeedLabel      = NSTextField(labelWithString: "↓ —")
    private let ulSpeedLabel      = NSTextField(labelWithString: "↑ —")
    private let freeSpaceLabel    = NSTextField(labelWithString: "Free: ?")
    private var cachedTooltip: String = ""

    private var observerToken: ObserverToken?

    init(appService: AppService) {
        self.appService = appService
        super.init(frame: .zero)
        setup()
        subscribeToService()
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    deinit {
        observerToken?.cancel()
    }

    // MARK: - Setup

    private func setup() {
        wantsLayer = true
        layer?.backgroundColor = Theme.bg.cgColor

        // Top separator line
        let separator = NSBox()
        separator.boxType = .separator
        separator.translatesAutoresizingMaskIntoConstraints = false

        [connectionLabel, torrentCountLabel, dlSpeedLabel, ulSpeedLabel, freeSpaceLabel].forEach {
            $0.font = .systemFont(ofSize: NSFont.smallSystemFontSize)
            $0.textColor = Theme.fgDark
            $0.translatesAutoresizingMaskIntoConstraints = false
        }

        addSubview(separator)
        addSubview(connectionLabel)
        addSubview(torrentCountLabel)
        addSubview(dlSpeedLabel)
        addSubview(ulSpeedLabel)
        addSubview(freeSpaceLabel)

        NSLayoutConstraint.activate([
            separator.leadingAnchor.constraint(equalTo: leadingAnchor),
            separator.trailingAnchor.constraint(equalTo: trailingAnchor),
            separator.topAnchor.constraint(equalTo: topAnchor),
            separator.heightAnchor.constraint(equalToConstant: 1),

            connectionLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 8),
            connectionLabel.centerYAnchor.constraint(equalTo: centerYAnchor),

            torrentCountLabel.leadingAnchor.constraint(equalTo: connectionLabel.trailingAnchor, constant: 12),
            torrentCountLabel.centerYAnchor.constraint(equalTo: centerYAnchor),

            dlSpeedLabel.centerXAnchor.constraint(equalTo: centerXAnchor, constant: -50),
            dlSpeedLabel.centerYAnchor.constraint(equalTo: centerYAnchor),

            ulSpeedLabel.centerXAnchor.constraint(equalTo: centerXAnchor, constant: 50),
            ulSpeedLabel.centerYAnchor.constraint(equalTo: centerYAnchor),

            freeSpaceLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -8),
            freeSpaceLabel.centerYAnchor.constraint(equalTo: centerYAnchor),

            heightAnchor.constraint(equalToConstant: 22),
        ])
    }

    private func subscribeToService() {
        let svc = appService
        observerToken = svc.addObserver { [weak self] event in
            switch event {
            case .torrentsUpdated, .statsUpdated:
                self?.update()
            case .sessionUpdated:
                self?.update()
                self?.updateConnection()
            case .freeSpaceUpdated:
                self?.updateFreeSpace()
            case .connectionStateChanged:
                self?.updateConnection()
            case .selectionChanged:
                break
            }
        }
        update()
        updateConnection()
    }

    // MARK: - Updates

    private func updateConnection() {
        let svc = appService
        let state = svc.connectionState
        
        let host: String
        if !svc.connectionHost.isEmpty {
            host = "\(svc.connectionHost):\(svc.connectionPort)"
        } else {
            host = S.Footer.notConfigured
        }
        
        let peerPort = svc.session.map { " · \($0.peerPort)" } ?? ""
        connectionLabel.stringValue = "\(state.indicator) \(host)\(peerPort)"
        
        let newTooltip = buildConnectionTooltip()
        if newTooltip != cachedTooltip {
            cachedTooltip = newTooltip
            connectionLabel.toolTip = cachedTooltip
        }
    }
    
    private func buildConnectionTooltip() -> String {
        let svc = appService
        var lines: [String] = []
        
        if let session = svc.session {
            lines.append(String(format: S.Footer.transmissionVersion, session.version))
            lines.append(String(format: S.Footer.rpcVersion, session.rpcVersionSemver))
            let portForward = session.portForwardingEnabled ? "enabled" : "disabled"
            lines.append(String(format: S.Footer.peerPort, session.peerPort, portForward))
        }
        
        if !svc.lastPortSyncResult.isEmpty {
            lines.append(String(format: S.Footer.portSync, svc.lastPortSyncResult))
        }
        
        if case .error(let msg) = svc.connectionState {
            lines.append("")
            lines.append(String(format: S.Footer.errorLine, msg))
        }
        
        return lines.joined(separator: "\n")
    }

    private func update() {
        let svc = appService
        let total = svc.torrents.count
        let active = svc.torrents.filter { $0.rateDownload > 0 || $0.rateUpload > 0 }.count
        torrentCountLabel.stringValue = active > 0
            ? S.Footer.torrentCount(total: total, active: active)
            : S.Footer.torrentCountNoActive(total: total)

        if let stats = svc.sessionStats {
            dlSpeedLabel.stringValue = "↓ \(Formatters.formatSpeed(stats.downloadSpeed))"
            ulSpeedLabel.stringValue = "↑ \(Formatters.formatSpeed(stats.uploadSpeed))"
        }
    }

    private func updateFreeSpace() {
        let bytes = appService.freeSpace
        freeSpaceLabel.stringValue = bytes > 0
            ? S.Footer.freeSpace(formatted: Formatters.formatBytes(bytes))
            : S.Footer.freeSpaceUnknown
    }
}
