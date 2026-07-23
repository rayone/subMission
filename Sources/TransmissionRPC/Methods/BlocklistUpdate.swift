import Foundation

private struct EmptyArgsEnc: Encodable {}

private struct BlocklistUpdateResponse: Decodable {
    let blocklist_size: Int?
    let blocklistSize: Int?

    var size: Int { blocklist_size ?? blocklistSize ?? 0 }
}

public extension RPCSession {
    @discardableResult
    func updateBlocklist() async throws -> Int {
        let resp = try await request(method: "blocklist-update", arguments: EmptyArgsEnc(), responseType: BlocklistUpdateResponse.self)
        return resp.size
    }
}
