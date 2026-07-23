import Foundation

private struct QueueMoveArgs: Encodable {
    let ids: [Int]
}

public extension RPCSession {
    func queueMoveTop(ids: [Int]) async throws {
        try await requestVoid(method: "queue-move-top", arguments: QueueMoveArgs(ids: ids))
    }

    func queueMoveUp(ids: [Int]) async throws {
        try await requestVoid(method: "queue-move-up", arguments: QueueMoveArgs(ids: ids))
    }

    func queueMoveDown(ids: [Int]) async throws {
        try await requestVoid(method: "queue-move-down", arguments: QueueMoveArgs(ids: ids))
    }

    func queueMoveBottom(ids: [Int]) async throws {
        try await requestVoid(method: "queue-move-bottom", arguments: QueueMoveArgs(ids: ids))
    }
}
