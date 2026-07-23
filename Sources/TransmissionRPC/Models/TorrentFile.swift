import Foundation

public struct TorrentFile: Codable, Sendable {
    public let name: String
    public let length: Int64
    public let bytesCompleted: Int64

    // Populated post-decode from fileStats or wanted/priorities arrays
    public var wanted: Bool
    public var priority: BandwidthPriority

    enum CodingKeys: String, CodingKey {
        case name, length, bytesCompleted
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        name = try c.decodeOrDefault(String.self, forKey: .name, default: "")
        length = try c.decodeOrDefault(Int64.self, forKey: .length, default: 0)
        bytesCompleted = try c.decodeOrDefault(Int64.self, forKey: .bytesCompleted, default: 0)
        wanted = true
        priority = .normal
    }

    public func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(name, forKey: .name)
        try c.encode(length, forKey: .length)
        try c.encode(bytesCompleted, forKey: .bytesCompleted)
    }
}
