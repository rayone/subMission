import Foundation

// MARK: - torrent-start/stop/verify/reannounce/remove/setLocation/renamePath

private struct IDsArgs: Encodable {
    let ids: [Int]?
}

private struct RemoveArgs: Encodable {
    let ids: [Int]
    let deleteLocalData: Bool
    enum CodingKeys: String, CodingKey {
        case ids
        case deleteLocalData = "delete-local-data"
    }
}

private struct SetLocationArgs: Encodable {
    let ids: [Int]
    let location: String
    let move: Bool
}

private struct RenamePathArgs: Encodable {
    let ids: [Int]
    let path: String
    let name: String
}

public extension RPCSession {
    func startTorrents(ids: [Int]?) async throws {
        try await requestVoid(method: "torrent-start", arguments: IDsArgs(ids: ids))
    }

    func stopTorrents(ids: [Int]?) async throws {
        try await requestVoid(method: "torrent-stop", arguments: IDsArgs(ids: ids))
    }

    func forceStartTorrents(ids: [Int]) async throws {
        try await requestVoid(method: "torrent-start-now", arguments: IDsArgs(ids: ids))
    }

    func verifyTorrents(ids: [Int]) async throws {
        try await requestVoid(method: "torrent-verify", arguments: IDsArgs(ids: ids))
    }

    func reannounceTorrents(ids: [Int]) async throws {
        try await requestVoid(method: "torrent-reannounce", arguments: IDsArgs(ids: ids))
    }

    func removeTorrents(ids: [Int], deleteData: Bool) async throws {
        try await requestVoid(method: "torrent-remove", arguments: RemoveArgs(ids: ids, deleteLocalData: deleteData))
    }

    func setLocation(ids: [Int], location: String, move: Bool) async throws {
        try await requestVoid(method: "torrent-set-location", arguments: SetLocationArgs(ids: ids, location: location, move: move))
    }

    func renamePath(id: Int, path: String, name: String) async throws {
        try await requestVoid(method: "torrent-rename-path", arguments: RenamePathArgs(ids: [id], path: path, name: name))
    }
}
