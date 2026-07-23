import Foundation

public struct Session: Codable, Sendable {
    // Speed limits
    public let speedLimitDown: Int
    public let speedLimitDownEnabled: Bool
    public let speedLimitUp: Int
    public let speedLimitUpEnabled: Bool
    public let altSpeedDown: Int
    public let altSpeedUp: Int
    public let altSpeedEnabled: Bool
    public let altSpeedTimeEnabled: Bool
    public let altSpeedTimeBegin: Int
    public let altSpeedTimeEnd: Int
    public let altSpeedTimeDay: Int

    // Directories
    public let downloadDir: String
    public let incompleteDir: String
    public let incompleteDirEnabled: Bool

    // Seeding
    public let seedRatioLimit: Double
    public let seedRatioLimited: Bool
    public let idleSeedingLimit: Int
    public let idleSeedingLimitEnabled: Bool

    // Queue
    public let downloadQueueEnabled: Bool
    public let downloadQueueSize: Int
    public let seedQueueEnabled: Bool
    public let seedQueueSize: Int
    public let queueStalledEnabled: Bool
    public let queueStalledMinutes: Int

    // Peers
    public let peerLimitGlobal: Int
    public let peerLimitPerTorrent: Int
    public let peerPort: Int
    public let peerPortRandomOnStart: Bool
    public let portForwardingEnabled: Bool

    // Protocol
    public let encryption: Encryption
    public let pexEnabled: Bool
    public let dhtEnabled: Bool
    public let lpdEnabled: Bool
    public let preferredTransports: String

    // Blocklist
    public let blocklistEnabled: Bool
    public let blocklistUrl: String
    public let blocklistSize: Int

    // Scripts
    public let scriptTorrentAddedEnabled: Bool
    public let scriptTorrentAddedFilename: String
    public let scriptTorrentDoneEnabled: Bool
    public let scriptTorrentDoneFilename: String
    public let scriptTorrentDoneSeedingEnabled: Bool
    public let scriptTorrentDoneSeedingFilename: String

    // Behavior
    public let startAddedTorrents: Bool
    public let trashOriginalTorrentFiles: Bool
    public let renamePartialFiles: Bool
    public let defaultTrackers: String
    public let antiBruteForceEnabled: Bool

    // Info (read-only)
    public let version: String
    public let rpcVersionSemver: String
    public let rpcVersion: Int

    enum CodingKeys: String, CodingKey {
        case speedLimitDown = "speed-limit-down"
        case speedLimitDownEnabled = "speed-limit-down-enabled"
        case speedLimitUp = "speed-limit-up"
        case speedLimitUpEnabled = "speed-limit-up-enabled"
        case altSpeedDown = "alt-speed-down"
        case altSpeedUp = "alt-speed-up"
        case altSpeedEnabled = "alt-speed-enabled"
        case altSpeedTimeEnabled = "alt-speed-time-enabled"
        case altSpeedTimeBegin = "alt-speed-time-begin"
        case altSpeedTimeEnd = "alt-speed-time-end"
        case altSpeedTimeDay = "alt-speed-time-day"
        case downloadDir = "download-dir"
        case incompleteDir = "incomplete-dir"
        case incompleteDirEnabled = "incomplete-dir-enabled"
        case seedRatioLimit = "seedRatioLimit"
        case seedRatioLimited = "seedRatioLimited"
        case idleSeedingLimit = "idle-seeding-limit"
        case idleSeedingLimitEnabled = "idle-seeding-limit-enabled"
        case downloadQueueEnabled = "download-queue-enabled"
        case downloadQueueSize = "download-queue-size"
        case seedQueueEnabled = "seed-queue-enabled"
        case seedQueueSize = "seed-queue-size"
        case queueStalledEnabled = "queue-stalled-enabled"
        case queueStalledMinutes = "queue-stalled-minutes"
        case peerLimitGlobal = "peer-limit-global"
        case peerLimitPerTorrent = "peer-limit-per-torrent"
        case peerPort = "peer-port"
        case peerPortRandomOnStart = "peer-port-random-on-start"
        case portForwardingEnabled = "port-forwarding-enabled"
        case encryption
        case pexEnabled = "pex-enabled"
        case dhtEnabled = "dht-enabled"
        case lpdEnabled = "lpd-enabled"
        case preferredTransports = "preferred-transport"
        case blocklistEnabled = "blocklist-enabled"
        case blocklistUrl = "blocklist-url"
        case blocklistSize = "blocklist-size"
        case scriptTorrentAddedEnabled = "script-torrent-added-enabled"
        case scriptTorrentAddedFilename = "script-torrent-added-filename"
        case scriptTorrentDoneEnabled = "script-torrent-done-enabled"
        case scriptTorrentDoneFilename = "script-torrent-done-filename"
        case scriptTorrentDoneSeedingEnabled = "script-torrent-done-seeding-enabled"
        case scriptTorrentDoneSeedingFilename = "script-torrent-done-seeding-filename"
        case startAddedTorrents = "start-added-torrents"
        case trashOriginalTorrentFiles = "trash-original-torrent-files"
        case renamePartialFiles = "rename-partial-files"
        case defaultTrackers = "default-trackers"
        case antiBruteForceEnabled = "anti-brute-force-enabled"
        case version
        case rpcVersionSemver = "rpc-version-semver"
        case rpcVersion = "rpc-version"
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)

        speedLimitDown = try c.decodeOrDefault(Int.self, forKey: .speedLimitDown, default: 0)
        speedLimitDownEnabled = try c.decodeOrDefault(Bool.self, forKey: .speedLimitDownEnabled, default: false)
        speedLimitUp = try c.decodeOrDefault(Int.self, forKey: .speedLimitUp, default: 0)
        speedLimitUpEnabled = try c.decodeOrDefault(Bool.self, forKey: .speedLimitUpEnabled, default: false)
        altSpeedDown = try c.decodeOrDefault(Int.self, forKey: .altSpeedDown, default: 50)
        altSpeedUp = try c.decodeOrDefault(Int.self, forKey: .altSpeedUp, default: 50)
        altSpeedEnabled = try c.decodeOrDefault(Bool.self, forKey: .altSpeedEnabled, default: false)
        altSpeedTimeEnabled = try c.decodeOrDefault(Bool.self, forKey: .altSpeedTimeEnabled, default: false)
        altSpeedTimeBegin = try c.decodeOrDefault(Int.self, forKey: .altSpeedTimeBegin, default: 540)
        altSpeedTimeEnd = try c.decodeOrDefault(Int.self, forKey: .altSpeedTimeEnd, default: 1020)
        altSpeedTimeDay = try c.decodeOrDefault(Int.self, forKey: .altSpeedTimeDay, default: 127)

        downloadDir = try c.decodeOrDefault(String.self, forKey: .downloadDir, default: "")
        incompleteDir = try c.decodeOrDefault(String.self, forKey: .incompleteDir, default: "")
        incompleteDirEnabled = try c.decodeOrDefault(Bool.self, forKey: .incompleteDirEnabled, default: false)

        seedRatioLimit = try c.decodeOrDefault(Double.self, forKey: .seedRatioLimit, default: 2.0)
        seedRatioLimited = try c.decodeOrDefault(Bool.self, forKey: .seedRatioLimited, default: false)
        idleSeedingLimit = try c.decodeOrDefault(Int.self, forKey: .idleSeedingLimit, default: 30)
        idleSeedingLimitEnabled = try c.decodeOrDefault(Bool.self, forKey: .idleSeedingLimitEnabled, default: false)

        downloadQueueEnabled = try c.decodeOrDefault(Bool.self, forKey: .downloadQueueEnabled, default: false)
        downloadQueueSize = try c.decodeOrDefault(Int.self, forKey: .downloadQueueSize, default: 5)
        seedQueueEnabled = try c.decodeOrDefault(Bool.self, forKey: .seedQueueEnabled, default: false)
        seedQueueSize = try c.decodeOrDefault(Int.self, forKey: .seedQueueSize, default: 10)
        queueStalledEnabled = try c.decodeOrDefault(Bool.self, forKey: .queueStalledEnabled, default: true)
        queueStalledMinutes = try c.decodeOrDefault(Int.self, forKey: .queueStalledMinutes, default: 30)

        peerLimitGlobal = try c.decodeOrDefault(Int.self, forKey: .peerLimitGlobal, default: 200)
        peerLimitPerTorrent = try c.decodeOrDefault(Int.self, forKey: .peerLimitPerTorrent, default: 50)
        peerPort = try c.decodeOrDefault(Int.self, forKey: .peerPort, default: 51413)
        peerPortRandomOnStart = try c.decodeOrDefault(Bool.self, forKey: .peerPortRandomOnStart, default: false)
        portForwardingEnabled = try c.decodeOrDefault(Bool.self, forKey: .portForwardingEnabled, default: true)

        let encRaw = try c.decodeOrDefault(String.self, forKey: .encryption, default: "preferred")
        encryption = Encryption(rawValue: encRaw) ?? .preferred
        pexEnabled = try c.decodeOrDefault(Bool.self, forKey: .pexEnabled, default: true)
        dhtEnabled = try c.decodeOrDefault(Bool.self, forKey: .dhtEnabled, default: true)
        lpdEnabled = try c.decodeOrDefault(Bool.self, forKey: .lpdEnabled, default: false)
        preferredTransports = try c.decodeOrDefault(String.self, forKey: .preferredTransports, default: "")

        blocklistEnabled = try c.decodeOrDefault(Bool.self, forKey: .blocklistEnabled, default: false)
        blocklistUrl = try c.decodeOrDefault(String.self, forKey: .blocklistUrl, default: "")
        blocklistSize = try c.decodeOrDefault(Int.self, forKey: .blocklistSize, default: 0)

        scriptTorrentAddedEnabled = try c.decodeOrDefault(Bool.self, forKey: .scriptTorrentAddedEnabled, default: false)
        scriptTorrentAddedFilename = try c.decodeOrDefault(String.self, forKey: .scriptTorrentAddedFilename, default: "")
        scriptTorrentDoneEnabled = try c.decodeOrDefault(Bool.self, forKey: .scriptTorrentDoneEnabled, default: false)
        scriptTorrentDoneFilename = try c.decodeOrDefault(String.self, forKey: .scriptTorrentDoneFilename, default: "")
        scriptTorrentDoneSeedingEnabled = try c.decodeOrDefault(Bool.self, forKey: .scriptTorrentDoneSeedingEnabled, default: false)
        scriptTorrentDoneSeedingFilename = try c.decodeOrDefault(String.self, forKey: .scriptTorrentDoneSeedingFilename, default: "")

        startAddedTorrents = try c.decodeOrDefault(Bool.self, forKey: .startAddedTorrents, default: true)
        trashOriginalTorrentFiles = try c.decodeOrDefault(Bool.self, forKey: .trashOriginalTorrentFiles, default: false)
        renamePartialFiles = try c.decodeOrDefault(Bool.self, forKey: .renamePartialFiles, default: true)
        defaultTrackers = try c.decodeOrDefault(String.self, forKey: .defaultTrackers, default: "")
        antiBruteForceEnabled = try c.decodeOrDefault(Bool.self, forKey: .antiBruteForceEnabled, default: false)

        version = try c.decodeOrDefault(String.self, forKey: .version, default: "")
        rpcVersionSemver = try c.decodeOrDefault(String.self, forKey: .rpcVersionSemver, default: "")
        rpcVersion = try c.decodeOrDefault(Int.self, forKey: .rpcVersion, default: 0)
    }
}
