import Foundation


public struct CBORStreamEncoder {

    public enum StreamableItemType: UInt8 {
        case map = 0xbf
        case array = 0x9f
        case string = 0x7f
        case byteString = 0x5f
    }

    private(set) var stream: CBOROutputStream

    public init(stream: CBOROutputStream) {
        self.stream = stream
    }

    /// Encodes a single CBOR item.
    ///
    /// - Throws:
    ///     - `Swift.Error`: If any I/O error occurs
    public func encode(_ value: CBOR) throws {
        switch value {
        case .null: try encodeNull()
        case .undefined: try encodeUndefined()
        case let .unsignedInt(ui): try encodeVarUInt(ui)
        case let .negativeInt(ni): try encodeNegativeInt(~Int64(bitPattern: ni))
        case let .byteString(bs): try encodeByteString(bs)
        case let .utf8String(str): try encodeString(str)
        case let .array(a): try encodeArray(a)
        case let .map(m): try encodeMap(m)
        case let .tagged(t, l): try encodeTagged(tag: t, value: l)
        case let .simple(s): try encodeSimpleValue(s)
        case let .boolean(b): try encodeBool(b)
        case let .half(h): try encodeHalf(h)
        case let .float(f): try encodeFloat(f)
        case let .double(d): try encodeDouble(d)
        }
    }

    /// Encodes any signed/unsigned integer, `or`ing `majorType` and `additional` data with first byte
    private func encodeInt(_ x: Int, majorType: UInt8, additional: UInt8 = 0) throws {
        try encodeInt(x, modifier: (majorType << 5) | (additional & 0x1f))
    }

    /// Encodes any signed/unsigned integer, `or`ing `modifier` with first byte
    private func encodeInt<T>(_ x: T, modifier: UInt8) throws where T : FixedWidthInteger, T : SignedInteger {
        if (x < 0) {
            try encodeNegativeInt(Int64(x), modifier: modifier)
        } else {
            try encodeVarUInt(UInt64(x), modifier: modifier)
        }
    }

    /// Encodes any standard signed integer item.
    ///
    /// - Throws:
    ///     - `Swift.Error`: If any I/O error occurs
    public func encodeInt<T>(_ x: T) throws where T : FixedWidthInteger, T : SignedInteger {
        try encodeInt(x, modifier: 0)
    }

    // MARK: - major 0: unsigned integer

    /// Encodes an 8bit unsigned integer, `or`ing `modifier` with first byte
    private func encodeUInt8(_ x: UInt8, modifier: UInt8 = 0) throws {
        if x < 24 {
            try stream.writeByte(x | modifier)
        }
        else {
            try stream.writeByte(0x18 | modifier)
            try stream.writeByte(x)
        }
    }

    /// Encodes a 16bit unsigned integer, `or`ing `modifier` with first byte
    private func encodeUInt16(_ x: UInt16, modifier: UInt8 = 0) throws {
        try stream.writeByte(0x19 | modifier)
        try stream.writeInt(x)
    }

    /// Encodes a 32bit unsigned integer, `or`ing `modifier` with first byte
    private func encodeUInt32(_ x: UInt32, modifier: UInt8 = 0) throws {
        try stream.writeByte(0x1a | modifier)
        try stream.writeInt(x)
    }

    /// Encodes a 64bit unsigned integer, `or`ing `modifier` with first byte
    private func encodeUInt64(_ x: UInt64, modifier: UInt8 = 0) throws {
        try stream.writeByte(0x1b | modifier)
        try stream.writeInt(x)
    }

    /// Encodes any standard unsigned integer item.
    ///
    /// - Throws:
    ///     - `Swift.Error`: If any I/O error occurs
    public func encodeUInt<T>(_ x: T) throws where T : FixedWidthInteger, T : UnsignedInteger {
        try encodeUInt(x, modifier: 0)
    }

    /// Encodes any unsigned integer, `or`ing `modifier` with first byte
    private func encodeUInt<T>(_ x: T, modifier: UInt8) throws where T : FixedWidthInteger, T : UnsignedInteger {
        try encodeVarUInt(UInt64(exactly: x)!, modifier: modifier)
    }

    /// Encodes any unsigned integer, `or`ing `modifier` with first byte
    private func encodeVarUInt(_ x: UInt64, modifier: UInt8 = 0) throws {
        switch x {
        case let x where x <= UInt8.max: try encodeUInt8(UInt8(x), modifier: modifier)
        case let x where x <= UInt16.max: try encodeUInt16(UInt16(x), modifier: modifier)
        case let x where x <= UInt32.max: try encodeUInt32(UInt32(x), modifier: modifier)
        default: try encodeUInt64(x, modifier: modifier)
        }
    }

    // MARK: - major 1: negative integer

    /// Encodes any negative integer item.
    ///
    /// - Throws:
    ///     - `Swift.Error`: If any I/O error occurs
    public func encodeNegativeInt(_ x: Int64) throws {
        try encodeNegativeInt(x, modifier: 0)
    }

    private func encodeNegativeInt(_ x: Int64, modifier: UInt8) throws {
        assert(x < 0)
        try encodeVarUInt(~UInt64(bitPattern: x), modifier: 0b001_00000 | modifier)
    }

    // MARK: - major 2: bytestring

    /// Encodes provided data as a byte string item.
    ///
    /// - Throws:
    ///     - `Swift.Error`: If any I/O error occurs
    public func encodeByteString(_ bs: Data) throws {
        try encodeInt(bs.count, majorType: 0b010)
        try stream.writeBytes(bs)
    }

    // MARK: - major 3: UTF8 string

    /// Encodes provided data as a UTF-8 string item.
    ///
    /// - Throws:
    ///     - `Swift.Error`: If any I/O error occurs
    public func encodeString(_ str: String) throws {
        let len = str.utf8.count
        try encodeInt(len, majorType: 0b011)
        try str.withCString { ptr in
            try ptr.withMemoryRebound(to: UInt8.self, capacity: len) { ptr in
                try stream.writeBytes(UnsafeBufferPointer(start: ptr, count: len))
            }
        }
    }

    // MARK: - major 4: array of data items

    /// Encodes an array of CBOR items.
    ///
    /// - Throws:
    ///     - `Swift.Error`: If any I/O error occurs
    public func encodeArray(_ arr: [CBOR]) throws {
        try encodeInt(arr.count, majorType: 0b100)
        try encodeArrayChunk(arr)
    }

    /// Encodes an array chunk of CBOR items.
    ///
    /// - Note: This is specifically for use when creating
    /// indefinite arrays; see `encodeStreamStart` & `encodeStreamEnd`.
    /// Any number of chunks can be encoded in an indefinite array.
    ///
    /// - Throws:
    ///     - `Swift.Error`: If any I/O error occurs
    public func encodeArrayChunk(_ chunk: [CBOR]) throws {
        for item in chunk {
            try encode(item)
        }
    }

    // MARK: - major 5: a map of pairs of data items

    /// Encodes a map of CBOR item pairs.
    ///
    /// - Throws:
    ///     - `Swift.Error`: If any I/O error occurs
    public func encodeMap(_ map: [CBOR: CBOR]) throws {
        try encodeInt(map.count, majorType: 0b101)
        try encodeMapChunk(map)
    }

    /// Encodes a map chunk of CBOR item pairs.
    ///
    /// - Note: This is specifically for use when creating
    /// indefinite maps; see `encodeStreamStart` & `encodeStreamEnd`.
    /// Any number of chunks can be encoded in an indefinite map.
    ///
    /// - Throws:
    ///     - `Swift.Error`: If any I/O error occurs
    public func encodeMapChunk(_ map: [CBOR: CBOR]) throws {
        for (k, v) in map {
            try encode(k)
            try encode(v)
        }
    }

    // MARK: - major 6: tagged values

    /// Encodes a tagged CBOR item.
    ///
    /// - Throws:
    ///     - `Swift.Error`: If any I/O error occurs
    public func encodeTagged(tag: CBOR.Tag, value: CBOR) throws {
        try encodeVarUInt(tag.rawValue, modifier: 0b110_00000)
        try encode(value)
    }

    // MARK: - major 7: floats, simple values, the 'break' stop code

    public func encodeSimpleValue(_ x: UInt8) throws {
        if x < 24 {
            try stream.writeByte(0b111_00000 | x)
        } else {
            try stream.writeByte(0xf8)
            try stream.writeByte(x)
        }
    }

    /// Encodes CBOR null item.
    ///
    /// - Throws:
    ///     - `Swift.Error`: If any I/O error occurs
    public func encodeNull() throws {
        try stream.writeByte(0xf6)
    }

    /// Encodes CBOR undefined item.
    ///
    /// - Throws:
    ///     - `Swift.Error`: If any I/O error occurs
    public func encodeUndefined() throws {
        try stream.writeByte(0xf7)
    }

    /// Encodes Float16 item.
    ///
    /// - Throws:
    ///     - `Swift.Error`: If any I/O error occurs
    public func encodeHalf(_ x: Half) throws {
        try stream.writeByte(0xfa)
        try stream.writeInt(x.bitPattern)
    }

    /// Encodes Float32 item.
    ///
    /// - Throws:
    ///     - `Swift.Error`: If any I/O error occurs
    public func encodeFloat(_ x: Float) throws {
        try stream.writeByte(0xfa)
        try stream.writeInt(x.bitPattern)
    }

    /// Encodes Float64 item.
    ///
    /// - Throws:
    ///     - `Swift.Error`: If any I/O error occurs
    public func encodeDouble(_ x: Double) throws {
        try stream.writeByte(0xfb)
        try stream.writeInt(x.bitPattern)
    }

    /// Encodes Bool item.
    ///
    /// - Throws:
    ///     - `Swift.Error`: If any I/O error occurs
    public func encodeBool(_ x: Bool) throws {
        try stream.writeByte(x ? 0xf5 : 0xf4)
    }

    // MARK: - Indefinite length items

    /// Encodes a CBOR value indicating the opening of an indefinite-length data item.
    /// The user is responsible encoding subsequent valid CBOR items.
    ///
    /// - Attention: The user must end the indefinite item encoding with the end
    /// indicator, which can be encoded with `encodeStreamEnd()`.
    ///
    /// - Parameters:
    ///     - type: The type of indefinite-item to begin encoding.
    ///         - map: Indefinite map item (requires encoding zero or more "pairs" of items only)
    ///         - array: Indefinite array item
    ///         - string: Indefinite string item (requires encoding zero or more `string` items only)
    ///         - byteString: Indefinite string item (requires encoding zero or more `byte-string` items only)
    /// - Throws:
    ///     - `Swift.Error`: If any I/O error occurs
    public func encodeIndefiniteStart(for type: StreamableItemType) throws {
        try stream.writeByte(type.rawValue)
    }

    // Encodes the indefinite-item end indicator.
    ///
    /// - Throws:
    ///     - `Swift.Error`: If any I/O error occurs
    public func encodeIndefiniteEnd() throws {
        try stream.writeByte(0xff)
    }

}
