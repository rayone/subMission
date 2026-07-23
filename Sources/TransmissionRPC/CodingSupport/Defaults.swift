import Foundation

// MARK: - @Default property wrapper

/// Provides a default value when JSON key is missing or null.
/// Usage: @Default<DefaultFalse> var foo: Bool
@propertyWrapper
public struct Default<T: DefaultValueProvider>: Codable, Sendable where T.Value: Sendable {
    public var wrappedValue: T.Value

    public init() { wrappedValue = T.defaultValue }
    public init(wrappedValue: T.Value) { self.wrappedValue = wrappedValue }

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if container.decodeNil() {
            wrappedValue = T.defaultValue
        } else {
            wrappedValue = (try? container.decode(T.Value.self)) ?? T.defaultValue
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(wrappedValue)
    }
}

public protocol DefaultValueProvider: Sendable {
    associatedtype Value: Codable & Sendable
    static var defaultValue: Value { get }
}

// Common default providers
public enum DefaultFalse: DefaultValueProvider {
    public static var defaultValue: Bool { false }
}
public enum DefaultTrue: DefaultValueProvider {
    public static var defaultValue: Bool { true }
}
public enum DefaultZeroInt: DefaultValueProvider {
    public static var defaultValue: Int { 0 }
}
public enum DefaultZeroInt64: DefaultValueProvider {
    public static var defaultValue: Int64 { 0 }
}
public enum DefaultZeroDouble: DefaultValueProvider {
    public static var defaultValue: Double { 0.0 }
}
public enum DefaultEmptyString: DefaultValueProvider {
    public static var defaultValue: String { "" }
}

// MARK: - Convenience decode helpers

extension KeyedDecodingContainer {
    /// Decode or return a default if the key is missing / null.
    public func decodeOrDefault<T: Decodable>(_ type: T.Type, forKey key: Key, default defaultValue: T) throws -> T {
        return (try? decodeIfPresent(type, forKey: key)) ?? defaultValue
    }
}
