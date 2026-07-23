import Foundation

public struct TransferStats: Codable, Sendable {
    public let uploadedBytes: Int64
    public let downloadedBytes: Int64
    public let filesAdded: Int
    public let sessionCount: Int
    public let secondsActive: Int64

    enum CodingKeys: String, CodingKey {
        case uploadedBytes = "uploadedBytes"
        case downloadedBytes = "downloadedBytes"
        case filesAdded = "filesAdded"
        case sessionCount = "sessionCount"
        case secondsActive = "secondsActive"
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        uploadedBytes = try c.decodeOrDefault(Int64.self, forKey: .uploadedBytes, default: 0)
        downloadedBytes = try c.decodeOrDefault(Int64.self, forKey: .downloadedBytes, default: 0)
        filesAdded = try c.decodeOrDefault(Int.self, forKey: .filesAdded, default: 0)
        sessionCount = try c.decodeOrDefault(Int.self, forKey: .sessionCount, default: 0)
        secondsActive = try c.decodeOrDefault(Int64.self, forKey: .secondsActive, default: 0)
    }
}

public struct SessionStats: Codable, Sendable {
    public let activeTorrentCount: Int
    public let downloadSpeed: Int64
    public let uploadSpeed: Int64
    public let pausedTorrentCount: Int
    public let torrentCount: Int
    public let cumulativeStats: TransferStats
    public let currentStats: TransferStats

    enum CodingKeys: String, CodingKey {
        case activeTorrentCount = "activeTorrentCount"
        case downloadSpeed = "downloadSpeed"
        case uploadSpeed = "uploadSpeed"
        case pausedTorrentCount = "pausedTorrentCount"
        case torrentCount = "torrentCount"
        case cumulativeStats = "cumulative-stats"
        case currentStats = "current-stats"
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        activeTorrentCount = try c.decodeOrDefault(Int.self, forKey: .activeTorrentCount, default: 0)
        downloadSpeed = try c.decodeOrDefault(Int64.self, forKey: .downloadSpeed, default: 0)
        uploadSpeed = try c.decodeOrDefault(Int64.self, forKey: .uploadSpeed, default: 0)
        pausedTorrentCount = try c.decodeOrDefault(Int.self, forKey: .pausedTorrentCount, default: 0)
        torrentCount = try c.decodeOrDefault(Int.self, forKey: .torrentCount, default: 0)
        let emptyStats = TransferStats.empty
        cumulativeStats = (try? c.decode(TransferStats.self, forKey: .cumulativeStats)) ?? emptyStats
        currentStats = (try? c.decode(TransferStats.self, forKey: .currentStats)) ?? emptyStats
    }
}

extension TransferStats {
    static let empty = TransferStats(uploadedBytes: 0, downloadedBytes: 0, filesAdded: 0, sessionCount: 0, secondsActive: 0)

    init(uploadedBytes: Int64, downloadedBytes: Int64, filesAdded: Int, sessionCount: Int, secondsActive: Int64) {
        self.uploadedBytes = uploadedBytes
        self.downloadedBytes = downloadedBytes
        self.filesAdded = filesAdded
        self.sessionCount = sessionCount
        self.secondsActive = secondsActive
    }
}
