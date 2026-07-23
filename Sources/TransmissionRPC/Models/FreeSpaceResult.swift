import Foundation

public struct FreeSpaceResult: Decodable, Sendable {
    public let path: String
    public let sizeBytes: Int64
    public let totalCapacity: Int64

    enum CodingKeys: String, CodingKey {
        case path
        case sizeBytes = "size-bytes"
        case totalCapacity = "total_capacity"
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        path = try c.decodeOrDefault(String.self, forKey: .path, default: "")
        sizeBytes = try c.decodeOrDefault(Int64.self, forKey: .sizeBytes, default: 0)
        totalCapacity = try c.decodeOrDefault(Int64.self, forKey: .totalCapacity, default: 0)
    }
}

public struct PortTestResult: Decodable, Sendable {
    public let isOpen: Bool

    enum CodingKeys: String, CodingKey {
        case isOpen = "port-is-open"
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        isOpen = try c.decodeOrDefault(Bool.self, forKey: .isOpen, default: false)
    }
}
