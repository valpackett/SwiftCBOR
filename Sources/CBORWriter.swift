#if canImport(Foundation)
import Foundation
#endif

func appendBigEndian<T: FixedWidthInteger>(_ value: T, to output: inout [UInt8]) {
    let size = MemoryLayout<T>.size
    for shift in stride(from: (size - 1) * 8, through: 0, by: -8) {
        output.append(UInt8(truncatingIfNeeded: value >> shift))
    }
}

func appendCBORArgument(_ value: UInt64, major: UInt8, to output: inout [UInt8]) {
    if value < 24 {
        output.append(major | UInt8(value))
    } else if value <= UInt64(UInt8.max) {
        output.append(major | 24)
        appendBigEndian(UInt8(value), to: &output)
    } else if value <= UInt64(UInt16.max) {
        output.append(major | 25)
        appendBigEndian(UInt16(value), to: &output)
    } else if value <= UInt64(UInt32.max) {
        output.append(major | 26)
        appendBigEndian(UInt32(value), to: &output)
    } else {
        output.append(major | 27)
        appendBigEndian(value, to: &output)
    }
}

func appendCBORInt64(_ value: Int64, to output: inout [UInt8]) {
    if value < 0 {
        appendCBORArgument(~UInt64(bitPattern: value), major: 0x20, to: &output)
    } else {
        appendCBORArgument(UInt64(value), major: 0x00, to: &output)
    }
}

func withCBOROutput(_ body: (inout [UInt8]) throws -> Void) rethrows -> [UInt8] {
    var output: [UInt8] = []
    try body(&output)
    return output
}

extension Int {
    public func encode(into output: inout [UInt8], options: CBOROptions = CBOROptions()) {
        appendCBORInt64(Int64(self), to: &output)
    }
}

extension Int8 {
    public func encode(into output: inout [UInt8], options: CBOROptions = CBOROptions()) {
        appendCBORInt64(Int64(self), to: &output)
    }
}

extension Int16 {
    public func encode(into output: inout [UInt8], options: CBOROptions = CBOROptions()) {
        appendCBORInt64(Int64(self), to: &output)
    }
}

extension Int32 {
    public func encode(into output: inout [UInt8], options: CBOROptions = CBOROptions()) {
        appendCBORInt64(Int64(self), to: &output)
    }
}

extension Int64 {
    public func encode(into output: inout [UInt8], options: CBOROptions = CBOROptions()) {
        appendCBORInt64(self, to: &output)
    }
}

extension UInt {
    public func encode(into output: inout [UInt8], options: CBOROptions = CBOROptions()) {
        appendCBORArgument(UInt64(self), major: 0x00, to: &output)
    }
}

extension UInt8 {
    public func encode(into output: inout [UInt8], options: CBOROptions = CBOROptions()) {
        appendCBORArgument(UInt64(self), major: 0x00, to: &output)
    }
}

extension UInt16 {
    public func encode(into output: inout [UInt8], options: CBOROptions = CBOROptions()) {
        output.append(0x19)
        appendBigEndian(self, to: &output)
    }
}

extension UInt32 {
    public func encode(into output: inout [UInt8], options: CBOROptions = CBOROptions()) {
        output.append(0x1a)
        appendBigEndian(self, to: &output)
    }
}

extension UInt64 {
    public func encode(into output: inout [UInt8], options: CBOROptions = CBOROptions()) {
        output.append(0x1b)
        appendBigEndian(self, to: &output)
    }
}

extension String {
    public func encode(into output: inout [UInt8], options: CBOROptions = CBOROptions()) {
        appendCBORArgument(UInt64(self.utf8.count), major: 0x60, to: &output)
        output.reserveCapacity(output.count + self.utf8.count)
        output.append(contentsOf: self.utf8)
    }
}

extension Float {
    public func encode(into output: inout [UInt8], options: CBOROptions = CBOROptions()) {
        if options.useShortestFloatEncoding {
            output.append(contentsOf: CBOR.encodePreferredFloat(self))
        } else {
            output.append(0xfa)
            appendBigEndian(self.bitPattern, to: &output)
        }
    }
}

extension Double {
    public func encode(into output: inout [UInt8], options: CBOROptions = CBOROptions()) {
        if options.useShortestFloatEncoding {
            output.append(contentsOf: CBOR.encodePreferredDouble(self))
        } else {
            output.append(0xfb)
            appendBigEndian(self.bitPattern, to: &output)
        }
    }
}

extension Bool {
    public func encode(into output: inout [UInt8], options: CBOROptions = CBOROptions()) {
        output.append(self ? 0xf5 : 0xf4)
    }
}

extension Optional where Wrapped: CBOREncodable {
    public func encode(into output: inout [UInt8], options: CBOROptions = CBOROptions()) {
        switch self {
        case let .some(wrapped):
            wrapped.encode(into: &output, options: options)
        case .none:
            output.append(0xf6)
        }
    }
}

extension Array where Element: CBOREncodable {
    public func encode(into output: inout [UInt8], options: CBOROptions = CBOROptions()) {
        appendCBORArray(self, into: &output, options: options)
    }
}

extension Dictionary where Key: CBOREncodable, Value: CBOREncodable {
    public func encode(into output: inout [UInt8], options: CBOROptions = CBOROptions()) {
        appendCBORMap(self, into: &output, options: options)
    }
}

func appendCBORMap<Key: CBOREncodable, Value: CBOREncodable>(
    _ map: [Key: Value],
    into output: inout [UInt8],
    options: CBOROptions
) {
    if options.forbidNonStringMapKeys {
        try! ensureStringKey(Key.self)
    }
    appendCBORArgument(UInt64(map.count), major: 0xa0, to: &output)

    if options.shouldSortMapKeys {
        let sortedEntries = map.map {
            (encodedKey: $0.key.encode(options: options), value: $0.value)
        }.sorted(by: {
            $0.encodedKey.lexicographicallyPrecedes($1.encodedKey)
        })

        for entry in sortedEntries {
            output.append(contentsOf: entry.encodedKey)
            entry.value.encode(into: &output, options: options)
        }
    } else {
        for (key, value) in map {
            key.encode(into: &output, options: options)
            value.encode(into: &output, options: options)
        }
    }
}

extension CBOR {
    public func encode(into output: inout [UInt8], options: CBOROptions = CBOROptions()) {
        switch self {
        case let .unsignedInt(value):
            appendCBORArgument(value, major: 0x00, to: &output)
        case let .negativeInt(value):
            appendCBORArgument(value, major: 0x20, to: &output)
        case let .byteString(value):
            appendCBORArgument(UInt64(value.count), major: 0x40, to: &output)
            output.append(contentsOf: value)
        case let .utf8String(value):
            value.encode(into: &output, options: options)
        case let .array(value):
            value.encode(into: &output, options: options)
        case let .map(value):
            appendCBORMap(value, into: &output, options: options)
        case let .tagged(tag, value):
            appendCBORArgument(tag.rawValue, major: 0xc0, to: &output)
            value.encode(into: &output, options: options)
        case let .simple(value):
            precondition(value < 24 || value >= 32, "CBOR simple values 24...31 are reserved")
            if value < 24 {
                output.append(0xe0 | value)
            } else {
                output.append(contentsOf: [0xf8, value])
            }
        case let .boolean(value):
            value.encode(into: &output, options: options)
        case .null:
            output.append(0xf6)
        case .undefined:
            output.append(0xf7)
        case let .half(value):
            output.append(contentsOf: CBOR.encodeHalf(value))
        case let .float(value):
            value.encode(into: &output, options: options)
        case let .double(value):
            value.encode(into: &output, options: options)
        case .break:
            output.append(0xff)
        #if canImport(Foundation)
        case let .date(value):
            output.append(contentsOf: CBOR.encodeDate(value, options: options))
        #endif
        }
    }
}

extension NSNull {
    public func encode(into output: inout [UInt8], options: CBOROptions = CBOROptions()) {
        output.append(0xf6)
    }
}

#if canImport(Foundation)
extension Date {
    public func encode(into output: inout [UInt8], options: CBOROptions = CBOROptions()) {
        output.append(contentsOf: CBOR.encodeDate(self, options: options))
    }
}

extension Data {
    public func encode(into output: inout [UInt8], options: CBOROptions = CBOROptions()) {
        appendCBORArgument(UInt64(self.count), major: 0x40, to: &output)
        output.reserveCapacity(output.count + self.count)
        output.append(contentsOf: self)
    }
}
#endif
