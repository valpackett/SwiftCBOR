
public protocol CBOREncodable {
    func encode() -> [UInt8]
}

extension CBOR: CBOREncodable {
    /// Encodes a wrapped CBOR value. CBOR.half (Float16) is not supported and encodes as `undefined`.
    public func encode() -> [UInt8] {
        switch self {
        case let .unsignedInt(ui): return CBOR.encodeVarUInt(ui)
        case let .negativeInt(ni): return CBOR.encodeNegativeInt(~Int64(bitPattern: ni))
        case let .byteString(bs): return CBOR.encodeByteString(bs)
        case let .utf8String(str): return str.encode()
        case let .array(a): return CBOR.encodeArray(a)
        case let .map(m): return CBOR.encodeMap(m)
        case let .tagged(t, l): return CBOR.encodeTagged(tag: t, value: l)
        case let .simple(s): return CBOR.encodeSimpleValue(s)
        case let .boolean(b): return b.encode()
        case .null: return CBOR.encodeNull()
        case .undefined: return CBOR.encodeUndefined()
        case .half(_): return CBOR.undefined.encode()
        case let .float(f): return f.encode()
        case let .double(d): return d.encode()
        case .break: return CBOR.encodeBreak()
        }
    }
}

extension Int: CBOREncodable {
    public func encode() -> [UInt8] {
        if (self < 0) {
            return CBOR.encodeNegativeInt(Int64(self))
        } else {
            return CBOR.encodeVarUInt(UInt64(self))
        }
    }
}

extension UInt: CBOREncodable {
    public func encode() -> [UInt8] {
        return CBOR.encodeVarUInt(UInt64(self))
    }
}

extension UInt8: CBOREncodable {
    public func encode() -> [UInt8] {
        return CBOR.encodeUInt8(self)
    }
}


extension UInt16: CBOREncodable {
    public func encode() -> [UInt8] {
        return CBOR.encodeUInt16(self)
    }
}


extension UInt64: CBOREncodable {
    public func encode() -> [UInt8] {
        return CBOR.encodeUInt64(self)
    }
}

extension UInt32: CBOREncodable {
    public func encode() -> [UInt8] {
        return CBOR.encodeUInt32(self)
    }
}

extension String: CBOREncodable {
    public func encode() -> [UInt8] {
        return CBOR.encodeString(self)
    }
}

extension Float: CBOREncodable {
    public func encode() -> [UInt8] {
        return CBOR.encodeFloat(self)
    }
}

extension Double: CBOREncodable {
    public func encode() -> [UInt8] {
        return CBOR.encodeDouble(self)
    }
}


extension Bool: CBOREncodable {
    public func encode() -> [UInt8] {
        return CBOR.encodeBool(self)
    }
}
