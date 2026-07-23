import Foundation

// MARK: - session-set

/// Only send fields that have changed. All properties optional.
public struct SessionPatch: Encodable, Sendable {
    public var speedLimitDown: Int?
    public var speedLimitDownEnabled: Bool?
    public var speedLimitUp: Int?
    public var speedLimitUpEnabled: Bool?
    public var altSpeedDown: Int?
    public var altSpeedUp: Int?
    public var altSpeedEnabled: Bool?
    public var altSpeedTimeEnabled: Bool?
    public var altSpeedTimeBegin: Int?
    public var altSpeedTimeEnd: Int?
    public var altSpeedTimeDay: Int?
    public var downloadDir: String?
    public var incompleteDir: String?
    public var incompleteDirEnabled: Bool?
    public var seedRatioLimit: Double?
    public var seedRatioLimited: Bool?
    public var idleSeedingLimit: Int?
    public var idleSeedingLimitEnabled: Bool?
    public var downloadQueueEnabled: Bool?
    public var downloadQueueSize: Int?
    public var seedQueueEnabled: Bool?
    public var seedQueueSize: Int?
    public var queueStalledEnabled: Bool?
    public var queueStalledMinutes: Int?
    public var peerLimitGlobal: Int?
    public var peerLimitPerTorrent: Int?
    public var peerPort: Int?
    public var peerPortRandomOnStart: Bool?
    public var portForwardingEnabled: Bool?
    public var encryption: String?
    public var pexEnabled: Bool?
    public var dhtEnabled: Bool?
    public var lpdEnabled: Bool?
    public var blocklistEnabled: Bool?
    public var blocklistUrl: String?
    public var scriptTorrentAddedEnabled: Bool?
    public var scriptTorrentAddedFilename: String?
    public var scriptTorrentDoneEnabled: Bool?
    public var scriptTorrentDoneFilename: String?
    public var scriptTorrentDoneSeedingEnabled: Bool?
    public var scriptTorrentDoneSeedingFilename: String?
    public var startAddedTorrents: Bool?
    public var trashOriginalTorrentFiles: Bool?
    public var renamePartialFiles: Bool?
    public var defaultTrackers: String?

    public init() {}

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
        case blocklistEnabled = "blocklist-enabled"
        case blocklistUrl = "blocklist-url"
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
    }
}

public extension RPCSession {
    func setSession(_ patch: SessionPatch) async throws {
        try await requestVoid(method: "session-set", arguments: patch)
    }
}
