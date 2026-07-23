import Foundation

public struct BandwidthGroup: Codable, Sendable {
    public let name: String
    public let honorsSessionLimits: Bool
    public let speedLimitDown: Int
    public let speedLimitDownEnabled: Bool
    public let speedLimitUp: Int
    public let speedLimitUpEnabled: Bool

    enum CodingKeys: String, CodingKey {
        case name
        case honorsSessionLimits = "honorsSessionLimits"
        case speedLimitDown = "speed-limit-down"
        case speedLimitDownEnabled = "speed-limit-down-enabled"
        case speedLimitUp = "speed-limit-up"
        case speedLimitUpEnabled = "speed-limit-up-enabled"
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        name = try c.decodeOrDefault(String.self, forKey: .name, default: "")
        honorsSessionLimits = try c.decodeOrDefault(Bool.self, forKey: .honorsSessionLimits, default: true)
        speedLimitDown = try c.decodeOrDefault(Int.self, forKey: .speedLimitDown, default: 0)
        speedLimitDownEnabled = try c.decodeOrDefault(Bool.self, forKey: .speedLimitDownEnabled, default: false)
        speedLimitUp = try c.decodeOrDefault(Int.self, forKey: .speedLimitUp, default: 0)
        speedLimitUpEnabled = try c.decodeOrDefault(Bool.self, forKey: .speedLimitUpEnabled, default: false)
    }
}
