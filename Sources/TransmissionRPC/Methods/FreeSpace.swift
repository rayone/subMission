import Foundation

private struct FreeSpaceArgs: Encodable {
    let path: String
}

public extension RPCSession {
    func freeSpace(path: String) async throws -> FreeSpaceResult {
        try await request(method: "free-space", arguments: FreeSpaceArgs(path: path), responseType: FreeSpaceResult.self)
    }
}
