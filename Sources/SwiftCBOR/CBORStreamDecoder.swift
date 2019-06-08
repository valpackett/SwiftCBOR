import Foundation

private typealias CBORError = CBORSerialization.Error

public struct CBORStreamDecoder {

    private let stream: CBORInputStream

    public init(stream: CBORInputStream) {
        self.stream = stream
    }

    private func readBinaryNumber(_ type: Float16.Type) throws -> Float16 {
        return Float16(bitPattern: try stream.readInt(UInt16.self))
    }

    private func readBinaryNumber(_ type: Float32.Type) throws -> Float32 {
        return Float32(bitPattern: try stream.readInt(UInt32.self))
    }

    private func readBinaryNumber(_ type: Float64.Type) throws -> Float64 {
        return Float64(bitPattern: try stream.readInt(UInt64.self))
    }

    private func readVarUInt(_ v: UInt8, base: UInt8) throws -> UInt64 {
        guard v > base + 0x17 else { return UInt64(v - base) }

        switch VarUIntSize(rawValue: v) {
        case .uint8: return UInt64(try stream.readInt(UInt8.self))
        case .uint16: return UInt64(try stream.readInt(UInt16.self))
        case .uint32: return UInt64(try stream.readInt(UInt32.self))
        case .uint64: return UInt64(try stream.readInt(UInt64.self))
        }
    }

    private func readLength(_ v: UInt8, base: UInt8) throws -> Int {
        let n = try readVarUInt(v, base: base)

        guard n <= Int.max else {
            throw CBORError.sequenceTooLong
        }

        return Int(n)
    }

    /// Decodes `count` CBOR items.
    ///
    /// - Returns: An array of the decoded items
    /// - Throws:
    ///     - `CBORSerialization.Error`: If corrupted data is encountered,
    ///     including `.invalidBreak` if a break indicator is encountered in
    ///     an item slot
    ///     - `Swift.Error`: If any I/O error occurs
    public func decodeItems(count: Int) throws -> [CBOR] {
        var result: [CBOR] = []
        for _ in 0 ..< count {
            let item = try decodeRequiredItem()
            result.append(item)
        }
        return result
    }

    /// Decodes CBOR items until an indefinite-element break indicator
    /// is encountered.
    ///
    /// - Returns: An array of the decoded items
    /// - Throws:
    ///     - `CBORSerialization.Error`: If corrupted data is encountered
    ///     - `Swift.Error`: If any I/O error occurs
    public func decodeItemsUntilBreak() throws -> [CBOR] {
        var result: [CBOR] = []
        while let item = try decodeItem() {
            result.append(item)
        }
        return result
    }

    /// Decodes `count` key-value pairs of CBOR items.
    ///
    /// - Returns: A map of the decoded key-value pairs
    /// - Throws:
    ///     - `CBORSerialization.Error`: If corrupted data is encountered,
    ///     including `.invalidBreak` if a break indicator is encountered in
    ///     the either the key or value slot
    ///     - `Swift.Error`: If any I/O error occurs
    public func decodeItemPairs(count: Int) throws -> [CBOR : CBOR] {
        var result: [CBOR: CBOR] = [:]
        for _ in 0 ..< count {
            let key = try decodeRequiredItem()
            let val = try decodeRequiredItem()
            result[key] = val
        }
        return result
    }

    /// Decodes key-value pairs of CBOR items until an indefinite-element
    /// break indicator is encontered.
    ///
    /// - Returns: A map of the decoded key-value pairs
    /// - Throws:
    ///     - `CBORSerialization.Error`: If corrupted data is encountered,
    ///     including `.invalidBreak` if a break indicator is encountered in
    ///     the value slot
    ///     - `Swift.Error`: If any I/O error occurs
    public func decodeItemPairsUntilBreak() throws -> [CBOR : CBOR] {
        var result: [CBOR: CBOR] = [:]
        while let key = try decodeItem() {
            let val = try decodeRequiredItem()
            result[key] = val
        }
        return result
    }

    /// Decodes any CBOR item that is not an indefinite-element break indicator.
    ///
    /// - Returns: A non-break CBOR item
    /// - Throws:
    ///     - `CBORSerialization.Error`: If corrupted data is encountered,
    ///     including `.invalidBreak` if an indefinite-element indicator is
    ///     encountered
    ///     - `Swift.Error`: If any I/O error occurs
    public func decodeRequiredItem() throws -> CBOR {
        guard let item = try decodeItem() else { throw CBORError.invalidBreak }
        return item
    }

    /// Decodes any CBOR item
    ///
    /// - Returns: A CBOR item or nil if an indefinite-element break indicator.
    /// - Throws:
    ///     - `CBORSerialization.Error`: If corrupted data is encountered
    ///     - `Swift.Error`: If any I/O error occurs
    public func decodeItem() throws -> CBOR? {
        let b = try stream.readByte()

        switch b {
        // positive integers
        case 0x00...0x1b:
            return .unsignedInt(try readVarUInt(b, base: 0x00))

        // negative integers
        case 0x20...0x3b:
            return .negativeInt(try readVarUInt(b, base: 0x20))

        // byte strings
        case 0x40...0x5b:
            let numBytes = try readLength(b, base: 0x40)
            return .byteString(try stream.readBytes(count: numBytes))
        case 0x5f:
            let values = try decodeItemsUntilBreak().map { cbor -> Data in
                guard case .byteString(let bytes) = cbor else { throw CBORError.invalidIndefiniteElement }
                return bytes
            }
            let numBytes = values.reduce(0) { $0 + $1.count }
            var bytes = Data(capacity: numBytes)
            values.forEach { bytes.append($0) }
            return .byteString(bytes)

        // utf-8 strings
        case 0x60...0x7b:
            let numBytes = try readLength(b, base: 0x60)
            guard let string = String(data: try stream.readBytes(count: numBytes), encoding: .utf8) else {
                throw CBORError.invalidUTF8String
            }
            return .utf8String(string)
        case 0x7f:
            return .utf8String(try decodeItemsUntilBreak().map { x -> String in
                guard case .utf8String(let r) = x else { throw CBORError.invalidIndefiniteElement }
                return r
            }.joined(separator: ""))

        // arrays
        case 0x80...0x9b:
            let itemCount = try readLength(b, base: 0x80)
            return .array(try decodeItems(count: itemCount))
        case 0x9f:
            return .array(try decodeItemsUntilBreak())

        // pairs
        case 0xa0...0xbb:
            let itemPairCount = try readLength(b, base: 0xa0)
            return .map(try decodeItemPairs(count: itemPairCount))
        case 0xbf:
            return .map(try decodeItemPairsUntilBreak())

        // tagged values
        case 0xc0...0xdb:
            let tag = try readVarUInt(b, base: 0xc0)
            let item = try decodeRequiredItem()
            return .tagged(CBOR.Tag(rawValue: tag), item)

        case 0xe0...0xf3: return .simple(b - 0xe0)
        case 0xf4: return .boolean(false)
        case 0xf5: return .boolean(true)
        case 0xf6: return .null
        case 0xf7: return .undefined
        case 0xf8: return .simple(try stream.readByte())

        case 0xf9:
            return .half(try readBinaryNumber(Float16.self))
        case 0xfa:
            return .float(try readBinaryNumber(Float32.self))
        case 0xfb:
            return .double(try readBinaryNumber(Float64.self))

        case 0xff: return nil
        default: throw CBORError.invalidItemType
        }
    }

}

private enum VarUIntSize: UInt8 {
    case uint8 = 0
    case uint16 = 1
    case uint32 = 2
    case uint64 = 3

    init(rawValue: UInt8) {
        switch rawValue & 0b11 {
        case 0: self = .uint8
        case 1: self = .uint16
        case 2: self = .uint32
        case 3: self = .uint64
        default: fatalError() // mask only allows values from 0-3
        }
    }
}
