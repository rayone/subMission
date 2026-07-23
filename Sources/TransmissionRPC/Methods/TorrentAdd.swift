import Foundation

// MARK: - torrent-add

public struct AddTorrentRequest: Encodable, Sendable {
    public var filename: String?        // magnet URL or path
    public var metainfo: String?        // base64-encoded .torrent data
    public var downloadDir: String?
    public var labels: [String]?
    public var paused: Bool?
    public var bandwidthPriority: Int?
    public var filesWanted: [Int]?
    public var filesUnwanted: [Int]?
    public var priorityHigh: [Int]?
    public var priorityNormal: [Int]?
    public var priorityLow: [Int]?
    public var sequentialDownload: Bool?

    public init(filename: String? = nil, metainfo: String? = nil) {
        self.filename = filename
        self.metainfo = metainfo
    }

    enum CodingKeys: String, CodingKey {
        case filename, metainfo, labels, paused
        case downloadDir = "download-dir"
        case bandwidthPriority = "bandwidthPriority"
        case filesWanted = "files-wanted"
        case filesUnwanted = "files-unwanted"
        case priorityHigh = "priority-high"
        case priorityNormal = "priority-normal"
        case priorityLow = "priority-low"
        case sequentialDownload = "sequentialDownload"
    }
}

public struct AddTorrentResult: Sendable {
    public enum Outcome: Sendable {
        case added(TorrentAdded)
        case duplicate(TorrentAdded)
    }
    public struct TorrentAdded: Decodable, Sendable {
        public let id: Int
        public let name: String
        public let hashString: String
    }
    public let outcome: Outcome
}

private struct TorrentAddResponse: Decodable {
    let torrentAdded: AddTorrentResult.TorrentAdded?
    let torrentDuplicate: AddTorrentResult.TorrentAdded?

    enum CodingKeys: String, CodingKey {
        case torrentAdded = "torrent-added"
        case torrentDuplicate = "torrent-duplicate"
    }
}

public extension RPCSession {
    func addTorrent(_ request: AddTorrentRequest) async throws -> AddTorrentResult {
        let resp = try await self.request(method: "torrent-add", arguments: request, responseType: TorrentAddResponse.self)
        if let added = resp.torrentAdded {
            return AddTorrentResult(outcome: .added(added))
        } else if let dup = resp.torrentDuplicate {
            return AddTorrentResult(outcome: .duplicate(dup))
        } else {
            throw RPCError.serverError("torrent-add response missing torrent-added or torrent-duplicate")
        }
    }
}
