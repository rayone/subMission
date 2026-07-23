import Foundation

// MARK: - session-get

private struct SessionGetArgs: Encodable {
    let fields: [String]?
}

public extension RPCSession {
    func fetchSession(fields: [String]? = nil) async throws -> Session {
        try await request(method: "session-get", arguments: SessionGetArgs(fields: fields), responseType: Session.self)
    }
}
