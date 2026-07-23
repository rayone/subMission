import Foundation

private struct GroupGetArgs: Encodable {
    let group: [String]?
}

private struct GroupGetResponse: Decodable {
    let group: [BandwidthGroup]
}

public extension RPCSession {
    func fetchGroups(names: [String]? = nil) async throws -> [BandwidthGroup] {
        let resp = try await request(method: "group-get", arguments: GroupGetArgs(group: names), responseType: GroupGetResponse.self)
        return resp.group
    }

    func setGroup(_ group: BandwidthGroup) async throws {
        try await requestVoid(method: "group-set", arguments: group)
    }
}
