import Foundation

public struct Peer: Codable, Sendable {
    public let address: String
    public let port: Int
    public let clientName: String
    public let rateToClient: Int64
    public let rateToPeer: Int64
    public let progress: Double
    public let flagStr: String
    public let isEncrypted: Bool
    public let isUTP: Bool

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        address = try c.decodeOrDefault(String.self, forKey: .address, default: "")
        port = try c.decodeOrDefault(Int.self, forKey: .port, default: 0)
        clientName = try c.decodeOrDefault(String.self, forKey: .clientName, default: "")
        rateToClient = try c.decodeOrDefault(Int64.self, forKey: .rateToClient, default: 0)
        rateToPeer = try c.decodeOrDefault(Int64.self, forKey: .rateToPeer, default: 0)
        progress = try c.decodeOrDefault(Double.self, forKey: .progress, default: 0)
        flagStr = try c.decodeOrDefault(String.self, forKey: .flagStr, default: "")
        isEncrypted = try c.decodeOrDefault(Bool.self, forKey: .isEncrypted, default: false)
        isUTP = try c.decodeOrDefault(Bool.self, forKey: .isUTP, default: false)
    }

    enum CodingKeys: String, CodingKey {
        case address, port, progress
        case clientName = "clientName"
        case rateToClient = "rateToClient"
        case rateToPeer = "rateToPeer"
        case flagStr = "flagStr"
        case isEncrypted = "isEncrypted"
        case isUTP = "isUTP"
    }
}
