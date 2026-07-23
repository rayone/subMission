import Foundation

private struct EmptyArgs: Encodable {}

public extension RPCSession {
    func fetchStats() async throws -> SessionStats {
        try await request(method: "session-stats", arguments: EmptyArgs(), responseType: SessionStats.self)
    }
}
