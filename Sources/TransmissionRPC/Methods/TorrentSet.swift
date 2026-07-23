import Foundation

// MARK: - TorrentPatch — all settable torrent fields

public struct TorrentPatch: Encodable, Sendable {
    public var downloadLimit: Int?
    public var downloadLimited: Bool?
    public var uploadLimit: Int?
    public var uploadLimited: Bool?
    public var honorsSessionLimits: Bool?
    public var bandwidthPriority: Int?
    public var seedRatioLimit: Double?
    public var seedRatioMode: Int?
    public var seedIdleLimit: Int?
    public var seedIdleMode: Int?
    public var peerLimit: Int?
    public var labels: [String]?
    public var group: String?
    public var trackerList: String?
    public var sequentialDownload: Bool?
    public var filesWanted: [Int]?
    public var filesUnwanted: [Int]?
    public var priorityHigh: [Int]?
    public var priorityNormal: [Int]?
    public var priorityLow: [Int]?

    public init() {}

    enum CodingKeys: String, CodingKey {
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
        case peerLimit = "peer-limit"
        case labels
        case group
        case trackerList = "trackerList"
        case sequentialDownload = "sequentialDownload"
        case filesWanted = "files-wanted"
        case filesUnwanted = "files-unwanted"
        case priorityHigh = "priority-high"
        case priorityNormal = "priority-normal"
        case priorityLow = "priority-low"
    }
}

private struct TorrentSetArguments: Encodable {
    let ids: [Int]
    let patch: TorrentPatch

    func encode(to encoder: Encoder) throws {
        // Encode IDs then merge patch fields into same container
        var c = encoder.container(keyedBy: DynamicKey.self)
        try c.encode(ids, forKey: DynamicKey("ids"))
        // Re-encode patch by encoding it then merging into our container
        let patchData = try JSONEncoder().encode(patch)
        if let dict = try JSONSerialization.jsonObject(with: patchData) as? [String: Any] {
            for (k, v) in dict {
                try c.encode(AnyEncodable(v), forKey: DynamicKey(k))
            }
        }
    }
}

private struct DynamicKey: CodingKey {
    var stringValue: String
    var intValue: Int? { nil }
    init(_ string: String) { stringValue = string }
    init?(stringValue: String) { self.stringValue = stringValue }
    init?(intValue: Int) { return nil }
}

private struct AnyEncodable: Encodable {
    let value: Any
    init(_ value: Any) { self.value = value }
    func encode(to encoder: Encoder) throws {
        var c = encoder.singleValueContainer()
        switch value {
        case let v as Bool: try c.encode(v)
        case let v as Int: try c.encode(v)
        case let v as Double: try c.encode(v)
        case let v as String: try c.encode(v)
        case let v as [Int]: try c.encode(v)
        case let v as [String]: try c.encode(v)
        default: try c.encodeNil()
        }
    }
}

public extension RPCSession {
    func setTorrent(ids: [Int], patch: TorrentPatch) async throws {
        let args = TorrentSetArguments(ids: ids, patch: patch)
        try await requestVoid(method: "torrent-set", arguments: args)
    }
}
