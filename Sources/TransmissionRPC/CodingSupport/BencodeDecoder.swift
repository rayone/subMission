import Foundation

// Minimal bencode decoder — enough to extract .torrent info dict.
// Supports integers, byte strings, lists, and dicts.

public enum BencodeValue {
    case int(Int)
    case bytes(Data)
    case list([BencodeValue])
    case dict([String: BencodeValue])

    public var string: String? {
        guard case .bytes(let d) = self else { return nil }
        return String(bytes: d, encoding: .utf8) ?? String(bytes: d, encoding: .isoLatin1)
    }
    public var int: Int? { if case .int(let v) = self { return v } else { return nil } }
    public var list: [BencodeValue]? { if case .list(let v) = self { return v } else { return nil } }
    public var dict: [String: BencodeValue]? { if case .dict(let v) = self { return v } else { return nil } }
    public subscript(key: String) -> BencodeValue? { dict?[key] }
}

public struct BencodeDecoder {
    public init() {}

    public func decode(_ data: Data) throws -> BencodeValue {
        var idx = data.startIndex
        return try parse(data, &idx)
    }

    private func parse(_ data: Data, _ idx: inout Data.Index) throws -> BencodeValue {
        guard idx < data.endIndex else { throw BencodeError.truncated }
        let b = data[idx]
        if b == UInt8(ascii: "i") {
            idx = data.index(after: idx)
            return .int(try parseInt(data, &idx))
        } else if b == UInt8(ascii: "l") {
            idx = data.index(after: idx)
            var items: [BencodeValue] = []
            while idx < data.endIndex && data[idx] != UInt8(ascii: "e") {
                items.append(try parse(data, &idx))
            }
            guard idx < data.endIndex else { throw BencodeError.truncated }
            idx = data.index(after: idx)
            return .list(items)
        } else if b == UInt8(ascii: "d") {
            idx = data.index(after: idx)
            var dict: [String: BencodeValue] = [:]
            while idx < data.endIndex && data[idx] != UInt8(ascii: "e") {
                let keyVal = try parseBytes(data, &idx)
                let key = String(bytes: keyVal, encoding: .utf8) ?? String(bytes: keyVal, encoding: .isoLatin1) ?? ""
                let val = try parse(data, &idx)
                dict[key] = val
            }
            guard idx < data.endIndex else { throw BencodeError.truncated }
            idx = data.index(after: idx)
            return .dict(dict)
        } else if b >= UInt8(ascii: "0") && b <= UInt8(ascii: "9") {
            return .bytes(try parseBytes(data, &idx))
        } else {
            throw BencodeError.unexpectedByte(b)
        }
    }

    private func parseInt(_ data: Data, _ idx: inout Data.Index) throws -> Int {
        var neg = false
        if idx < data.endIndex && data[idx] == UInt8(ascii: "-") {
            neg = true
            idx = data.index(after: idx)
        }
        var result = 0
        var digits = 0
        while idx < data.endIndex && data[idx] != UInt8(ascii: "e") {
            let d = data[idx]
            guard d >= UInt8(ascii: "0") && d <= UInt8(ascii: "9") else { throw BencodeError.badInteger }
            let mult = result.multipliedReportingOverflow(by: 10)
            if mult.overflow { throw BencodeError.overflow }
            let add = mult.partialValue.addingReportingOverflow(Int(d - UInt8(ascii: "0")))
            if add.overflow { throw BencodeError.overflow }
            result = add.partialValue
            digits += 1
            idx = data.index(after: idx)
        }
        guard digits > 0 && idx < data.endIndex else { throw BencodeError.truncated }
        idx = data.index(after: idx) // consume 'e'
        return neg ? -result : result
    }

    private func parseBytes(_ data: Data, _ idx: inout Data.Index) throws -> Data {
        var len = 0
        while idx < data.endIndex && data[idx] != UInt8(ascii: ":") {
            let d = data[idx]
            guard d >= UInt8(ascii: "0") && d <= UInt8(ascii: "9") else { throw BencodeError.badLength }
            let mult = len.multipliedReportingOverflow(by: 10)
            if mult.overflow { throw BencodeError.overflow }
            let add = mult.partialValue.addingReportingOverflow(Int(d - UInt8(ascii: "0")))
            if add.overflow { throw BencodeError.overflow }
            len = add.partialValue
            idx = data.index(after: idx)
        }
        guard idx < data.endIndex else { throw BencodeError.truncated }
        idx = data.index(after: idx) // consume ':'
        guard let end = data.index(idx, offsetBy: len, limitedBy: data.endIndex), end <= data.endIndex else {
            throw BencodeError.truncated
        }
        let bytes = data[idx..<end]
        idx = end
        return bytes
    }
}

public enum BencodeError: Error {
    case truncated, badInteger, badLength, unexpectedByte(UInt8), overflow
}
