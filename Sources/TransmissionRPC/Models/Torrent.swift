import Foundation

// MARK: - ContentEquatable

public protocol ContentEquatable: Sendable {
    func isContentEqual(to other: Self) -> Bool
}

// MARK: - PeersFrom

public struct PeersFrom: Codable, Sendable, Equatable {
    public let fromCache: Int
    public let fromDht: Int
    public let fromIncoming: Int
    public let fromLpd: Int
    public let fromLtep: Int
    public let fromPex: Int
    public let fromTracker: Int

    public init() {
        fromCache = 0; fromDht = 0; fromIncoming = 0
        fromLpd = 0; fromLtep = 0; fromPex = 0; fromTracker = 0
    }

    enum CodingKeys: String, CodingKey {
        case fromCache = "from-cache"
        case fromDht = "from-dht"
        case fromIncoming = "from-incoming"
        case fromLpd = "from-lpd"
        case fromLtep = "from-ltep"
        case fromPex = "from-pex"
        case fromTracker = "from-tracker"
    }
}

// MARK: - FileStats

public struct FileStats: Codable, Sendable {
    public let bytesCompleted: Int64
    public let wanted: Bool
    public let priority: Int

    enum CodingKeys: String, CodingKey {
        case bytesCompleted = "bytesCompleted"
        case wanted
        case priority
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        bytesCompleted = try c.decodeOrDefault(Int64.self, forKey: .bytesCompleted, default: 0)
        wanted = try c.decodeOrDefault(Bool.self, forKey: .wanted, default: true)
        priority = try c.decodeOrDefault(Int.self, forKey: .priority, default: 0)
    }
}

// MARK: - Torrent

public struct Torrent: Codable, Sendable, Identifiable, ContentEquatable {

    // MARK: Identity & Metadata
    public let id: Int
    public let name: String
    public let hashString: String
    public let comment: String
    public let creator: String
    public let dateCreated: Int
    public let magnetLink: String
    public let isPrivate: Bool
    public let totalSize: Int64
    public let pieceCount: Int
    public let pieceSize: Int64
    public let fileCount: Int
    public let primaryMimeType: String

    // MARK: Status & Progress
    public let status: TorrentStatus
    public let error: Int
    public let errorString: String
    public let percentDone: Double
    public let metadataPercentComplete: Double
    public let recheckProgress: Double
    public let isFinished: Bool
    public let isStalled: Bool
    public let eta: Int
    public let etaIdle: Int
    public let leftUntilDone: Int64
    public let sizeWhenDone: Int64
    public let haveValid: Int64
    public let haveUnchecked: Int64
    public let desiredAvailable: Int64
    public let corruptEver: Int64

    // MARK: Transfer
    public let rateDownload: Int64
    public let rateUpload: Int64
    public let downloadedEver: Int64
    public let uploadedEver: Int64
    public let uploadRatio: Double
    public let secondsDownloading: Int
    public let secondsSeeding: Int64

    // MARK: Speed Limits (per-torrent)
    public let downloadLimit: Int
    public let downloadLimited: Bool
    public let uploadLimit: Int
    public let uploadLimited: Bool
    public let honorsSessionLimits: Bool
    public let bandwidthPriority: BandwidthPriority

    // MARK: Seeding Limits
    public let seedRatioLimit: Double
    public let seedRatioMode: SeedMode
    public let seedIdleLimit: Int
    public let seedIdleMode: SeedMode

    // MARK: Queue & Location
    public let queuePosition: Int
    public let downloadDir: String

    // MARK: Dates
    public let addedDate: Int
    public let doneDate: Int
    public let startDate: Int
    public let activityDate: Int
    public let editDate: Int

    // MARK: Peers
    public let peersConnected: Int
    public let peersSendingToUs: Int
    public let peersGettingFromUs: Int
    public let webseedsSendingToUs: Int
    public let maxConnectedPeers: Int
    public let peerLimit: Int
    public let peers: [Peer]
    public let peersFrom: PeersFrom

    // MARK: Trackers
    public let trackers: [Tracker]
    public let trackerStats: [TrackerStat]
    public let trackerList: String

    // MARK: Files
    public let files: [TorrentFile]
    public let fileStats: [FileStats]
    public let wanted: [Bool]
    public let priorities: [Int]

    // MARK: Pieces & Availability
    public let pieces: String
    public let availability: [Int]

    // MARK: Labels & Groups
    public let labels: [String]
    public let group: String

    // MARK: Sequential
    public let sequentialDownload: Bool

    // MARK: - ContentEquatable
    // Compare all fields that affect UI display (excludes peers, trackerStats, files, pieces)
    public func isContentEqual(to other: Torrent) -> Bool {
        return id == other.id &&
            name == other.name &&
            status == other.status &&
            error == other.error &&
            errorString == other.errorString &&
            percentDone == other.percentDone &&
            metadataPercentComplete == other.metadataPercentComplete &&
            recheckProgress == other.recheckProgress &&
            isFinished == other.isFinished &&
            isStalled == other.isStalled &&
            eta == other.eta &&
            etaIdle == other.etaIdle &&
            leftUntilDone == other.leftUntilDone &&
            sizeWhenDone == other.sizeWhenDone &&
            haveValid == other.haveValid &&
            rateDownload == other.rateDownload &&
            rateUpload == other.rateUpload &&
            downloadedEver == other.downloadedEver &&
            uploadedEver == other.uploadedEver &&
            uploadRatio == other.uploadRatio &&
            queuePosition == other.queuePosition &&
            downloadDir == other.downloadDir &&
            peersConnected == other.peersConnected &&
            peersSendingToUs == other.peersSendingToUs &&
            peersGettingFromUs == other.peersGettingFromUs &&
            labels == other.labels &&
            group == other.group &&
            downloadLimit == other.downloadLimit &&
            downloadLimited == other.downloadLimited &&
            uploadLimit == other.uploadLimit &&
            uploadLimited == other.uploadLimited &&
            bandwidthPriority == other.bandwidthPriority &&
            seedRatioLimit == other.seedRatioLimit &&
            seedRatioMode == other.seedRatioMode &&
            seedIdleLimit == other.seedIdleLimit &&
            seedIdleMode == other.seedIdleMode &&
            sequentialDownload == other.sequentialDownload
    }

    // MARK: - Codable
    enum CodingKeys: String, CodingKey {
        case id, name, comment, creator, magnetLink, error, isPrivate, isFinished, isStalled
        case eta, labels, group, pieces, availability, wanted, priorities, trackerList
        case hashString = "hashString"
        case dateCreated = "dateCreated"
        case totalSize = "totalSize"
        case pieceCount = "pieceCount"
        case pieceSize = "pieceSize"
        case fileCount = "file-count"
        case primaryMimeType = "primary-mime-type"
        case status
        case errorString = "errorString"
        case percentDone = "percentDone"
        case metadataPercentComplete = "metadataPercentComplete"
        case recheckProgress = "recheckProgress"
        case etaIdle = "etaIdle"
        case leftUntilDone = "leftUntilDone"
        case sizeWhenDone = "sizeWhenDone"
        case haveValid = "haveValid"
        case haveUnchecked = "haveUnchecked"
        case desiredAvailable = "desiredAvailable"
        case corruptEver = "corruptEver"
        case rateDownload = "rateDownload"
        case rateUpload = "rateUpload"
        case downloadedEver = "downloadedEver"
        case uploadedEver = "uploadedEver"
        case uploadRatio = "uploadRatio"
        case secondsDownloading = "secondsDownloading"
        case secondsSeeding = "secondsSeeding"
        case downloadLimit = "downloadLimit"
        case downloadLimited = "downloadLimited"
        case uploadLimit = "uploadLimit"
        case uploadLimited = "uploadLimited"
        case honorsSessionLimits = "honorsSessionLimits"
        case bandwidthPriority = "bandwidthPriority"
        case seedRatioLimit = "seedRatioLimit"
        case seedRatioMode = "seedRatioMode"
        case seedIdleLimit = "seedIdleLimit"
        case seedIdleMode = "seedIdleMode"
        case queuePosition = "queuePosition"
        case downloadDir = "downloadDir"
        case addedDate = "addedDate"
        case doneDate = "doneDate"
        case startDate = "startDate"
        case activityDate = "activityDate"
        case editDate = "editDate"
        case peersConnected = "peersConnected"
        case peersSendingToUs = "peersSendingToUs"
        case peersGettingFromUs = "peersGettingFromUs"
        case webseedsSendingToUs = "webseedsSendingToUs"
        case maxConnectedPeers = "maxConnectedPeers"
        case peerLimit = "peer-limit"
        case peers
        case peersFrom = "peersFrom"
        case trackers
        case trackerStats = "trackerStats"
        case files
        case fileStats = "fileStats"
        case sequentialDownload = "sequentialDownload"
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)

        id = try c.decode(Int.self, forKey: .id)
        name = try c.decodeOrDefault(String.self, forKey: .name, default: "")
        hashString = try c.decodeOrDefault(String.self, forKey: .hashString, default: "")
        comment = try c.decodeOrDefault(String.self, forKey: .comment, default: "")
        creator = try c.decodeOrDefault(String.self, forKey: .creator, default: "")
        dateCreated = try c.decodeOrDefault(Int.self, forKey: .dateCreated, default: 0)
        magnetLink = try c.decodeOrDefault(String.self, forKey: .magnetLink, default: "")
        isPrivate = try c.decodeOrDefault(Bool.self, forKey: .isPrivate, default: false)
        totalSize = try c.decodeOrDefault(Int64.self, forKey: .totalSize, default: 0)
        pieceCount = try c.decodeOrDefault(Int.self, forKey: .pieceCount, default: 0)
        pieceSize = try c.decodeOrDefault(Int64.self, forKey: .pieceSize, default: 0)
        fileCount = try c.decodeOrDefault(Int.self, forKey: .fileCount, default: 0)
        primaryMimeType = try c.decodeOrDefault(String.self, forKey: .primaryMimeType, default: "")

        let rawStatus = try c.decodeOrDefault(Int.self, forKey: .status, default: 0)
        status = TorrentStatus(rawValue: rawStatus) ?? .stopped
        error = try c.decodeOrDefault(Int.self, forKey: .error, default: 0)
        errorString = try c.decodeOrDefault(String.self, forKey: .errorString, default: "")
        percentDone = try c.decodeOrDefault(Double.self, forKey: .percentDone, default: 0)
        metadataPercentComplete = try c.decodeOrDefault(Double.self, forKey: .metadataPercentComplete, default: 0)
        recheckProgress = try c.decodeOrDefault(Double.self, forKey: .recheckProgress, default: 0)
        isFinished = try c.decodeOrDefault(Bool.self, forKey: .isFinished, default: false)
        isStalled = try c.decodeOrDefault(Bool.self, forKey: .isStalled, default: false)
        eta = try c.decodeOrDefault(Int.self, forKey: .eta, default: -1)
        etaIdle = try c.decodeOrDefault(Int.self, forKey: .etaIdle, default: -1)
        leftUntilDone = try c.decodeOrDefault(Int64.self, forKey: .leftUntilDone, default: 0)
        sizeWhenDone = try c.decodeOrDefault(Int64.self, forKey: .sizeWhenDone, default: 0)
        haveValid = try c.decodeOrDefault(Int64.self, forKey: .haveValid, default: 0)
        haveUnchecked = try c.decodeOrDefault(Int64.self, forKey: .haveUnchecked, default: 0)
        desiredAvailable = try c.decodeOrDefault(Int64.self, forKey: .desiredAvailable, default: 0)
        corruptEver = try c.decodeOrDefault(Int64.self, forKey: .corruptEver, default: 0)

        rateDownload = try c.decodeOrDefault(Int64.self, forKey: .rateDownload, default: 0)
        rateUpload = try c.decodeOrDefault(Int64.self, forKey: .rateUpload, default: 0)
        downloadedEver = try c.decodeOrDefault(Int64.self, forKey: .downloadedEver, default: 0)
        uploadedEver = try c.decodeOrDefault(Int64.self, forKey: .uploadedEver, default: 0)
        uploadRatio = try c.decodeOrDefault(Double.self, forKey: .uploadRatio, default: 0)
        secondsDownloading = try c.decodeOrDefault(Int.self, forKey: .secondsDownloading, default: 0)
        secondsSeeding = try c.decodeOrDefault(Int64.self, forKey: .secondsSeeding, default: 0)

        downloadLimit = try c.decodeOrDefault(Int.self, forKey: .downloadLimit, default: 0)
        downloadLimited = try c.decodeOrDefault(Bool.self, forKey: .downloadLimited, default: false)
        uploadLimit = try c.decodeOrDefault(Int.self, forKey: .uploadLimit, default: 0)
        uploadLimited = try c.decodeOrDefault(Bool.self, forKey: .uploadLimited, default: false)
        honorsSessionLimits = try c.decodeOrDefault(Bool.self, forKey: .honorsSessionLimits, default: true)
        let bpRaw = try c.decodeOrDefault(Int.self, forKey: .bandwidthPriority, default: 0)
        bandwidthPriority = BandwidthPriority(rawValue: bpRaw) ?? .normal

        seedRatioLimit = try c.decodeOrDefault(Double.self, forKey: .seedRatioLimit, default: 0)
        let srmRaw = try c.decodeOrDefault(Int.self, forKey: .seedRatioMode, default: 0)
        seedRatioMode = SeedMode(rawValue: srmRaw) ?? .useGlobal
        seedIdleLimit = try c.decodeOrDefault(Int.self, forKey: .seedIdleLimit, default: 0)
        let simRaw = try c.decodeOrDefault(Int.self, forKey: .seedIdleMode, default: 0)
        seedIdleMode = SeedMode(rawValue: simRaw) ?? .useGlobal

        queuePosition = try c.decodeOrDefault(Int.self, forKey: .queuePosition, default: 0)
        downloadDir = try c.decodeOrDefault(String.self, forKey: .downloadDir, default: "")

        addedDate = try c.decodeOrDefault(Int.self, forKey: .addedDate, default: 0)
        doneDate = try c.decodeOrDefault(Int.self, forKey: .doneDate, default: 0)
        startDate = try c.decodeOrDefault(Int.self, forKey: .startDate, default: 0)
        activityDate = try c.decodeOrDefault(Int.self, forKey: .activityDate, default: 0)
        editDate = try c.decodeOrDefault(Int.self, forKey: .editDate, default: 0)

        peersConnected = try c.decodeOrDefault(Int.self, forKey: .peersConnected, default: 0)
        peersSendingToUs = try c.decodeOrDefault(Int.self, forKey: .peersSendingToUs, default: 0)
        peersGettingFromUs = try c.decodeOrDefault(Int.self, forKey: .peersGettingFromUs, default: 0)
        webseedsSendingToUs = try c.decodeOrDefault(Int.self, forKey: .webseedsSendingToUs, default: 0)
        maxConnectedPeers = try c.decodeOrDefault(Int.self, forKey: .maxConnectedPeers, default: 0)
        peerLimit = try c.decodeOrDefault(Int.self, forKey: .peerLimit, default: 0)
        peers = (try? c.decode([Peer].self, forKey: .peers)) ?? []
        peersFrom = (try? c.decode(PeersFrom.self, forKey: .peersFrom)) ?? PeersFrom()

        trackers = (try? c.decode([Tracker].self, forKey: .trackers)) ?? []
        trackerStats = (try? c.decode([TrackerStat].self, forKey: .trackerStats)) ?? []
        trackerList = try c.decodeOrDefault(String.self, forKey: .trackerList, default: "")

        files = (try? c.decode([TorrentFile].self, forKey: .files)) ?? []
        let rawFileStats = (try? c.decode([FileStats].self, forKey: .fileStats)) ?? []
        fileStats = rawFileStats
        wanted = (try? c.decode([Bool].self, forKey: .wanted)) ?? []
        priorities = (try? c.decode([Int].self, forKey: .priorities)) ?? []

        pieces = try c.decodeOrDefault(String.self, forKey: .pieces, default: "")
        availability = (try? c.decode([Int].self, forKey: .availability)) ?? []

        labels = (try? c.decode([String].self, forKey: .labels)) ?? []
        group = try c.decodeOrDefault(String.self, forKey: .group, default: "")
        sequentialDownload = try c.decodeOrDefault(Bool.self, forKey: .sequentialDownload, default: false)
    }
}

// MARK: - Helpers

public extension Torrent {
    /// The root path argument for torrent-rename-path.
    /// Uses the first path component from the file list, which reflects the
    /// actual name on disk (not the display name which may have been updated
    /// locally before the server reflects it).
    var rootPathForRename: String {
        if let firstName = files.first?.name {
            return firstName.components(separatedBy: "/").first ?? name
        }
        return name
    }
}
