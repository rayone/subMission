import Foundation

// MARK: - Enums

public enum TorrentStatus: Int, Codable, Sendable {
    case stopped = 0
    case queuedVerify = 1
    case verifying = 2
    case queuedDownload = 3
    case downloading = 4
    case queuedSeed = 5
    case seeding = 6
}

public enum BandwidthPriority: Int, Codable, Sendable {
    case low = -1
    case normal = 0
    case high = 1
}

public enum SeedMode: Int, Codable, Sendable {
    case useGlobal = 0
    case useTorrent = 1
    case unlimited = 2
}

public enum Encryption: String, Codable, Sendable {
    case required
    case preferred
    case allowed = "tolerated"
}

public enum IPProtocol: String, Codable, Sendable {
    case ipv4
    case ipv6
}
