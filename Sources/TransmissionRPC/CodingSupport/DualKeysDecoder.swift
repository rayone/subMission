import Foundation

// DualKeysDecoder: utility for fields that changed names between Transmission versions.
// Use the decode helpers on RPCSession extension or model init when a field may come from
// either its new (4.1+ snake_case) or legacy (camelCase / kebab-case) name.

extension KeyedDecodingContainer {
    /// Try the primary key first, then fall back to the legacy key, then use the default.
    public func decodeWithLegacy<T: Decodable>(
        _ type: T.Type,
        primaryKey: Key,
        legacyKey: Key,
        default defaultValue: T
    ) throws -> T {
        if let v = try? decodeIfPresent(type, forKey: primaryKey) { return v }
        if let v = try? decodeIfPresent(type, forKey: legacyKey) { return v }
        return defaultValue
    }
}
