import Foundation

private struct PortTestArgs: Encodable {
    let ipProtocol: String?
    enum CodingKeys: String, CodingKey {
        case ipProtocol = "ip-protocol"
    }
}

public extension RPCSession {
    func portTest(protocol ipProtocol: IPProtocol? = nil) async throws -> PortTestResult {
        let args = PortTestArgs(ipProtocol: ipProtocol?.rawValue)
        return try await request(method: "port-test", arguments: args, responseType: PortTestResult.self)
    }
}
