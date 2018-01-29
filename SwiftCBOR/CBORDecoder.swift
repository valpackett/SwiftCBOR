public enum CBORError : Error {
	case unfinishedSequence
	case wrongTypeInsideSequence
	case incorrectUTF8String
}

extension CBOR {
    static public func decode(_ input: [UInt8]) throws -> CBOR? {
        return try CBORDecoder(input: input).decodeItem()
    }
}

public class CBORDecoder {

	private var istream : CBORInputStream

	public init(stream: CBORInputStream) {
		istream = stream
	}

	public init(input: ArraySlice<UInt8>) {
		istream = ArraySliceUInt8(slice: input)
	}

	public init(input: [UInt8]) {
		istream = ArrayUInt8(array: input)
	}

	private func readUInt<T: UnsignedInteger>(_ n: Int) throws -> T {
        return UnsafeRawPointer(Array(try istream.popBytes(n).reversed())).load(as: T.self)
	}

	private func readN(_ n: Int) throws -> [CBOR] {
		return try (0..<n).map { _ in guard let r = try decodeItem() else { throw CBORError.unfinishedSequence }; return r }
	}

	private func readUntilBreak() throws -> [CBOR] {
		var result : [CBOR] = []
		var cur = try decodeItem()
		while (cur != CBOR.break) {
			guard let curr = cur else { throw CBORError.unfinishedSequence }
			result.append(curr)
			cur = try decodeItem()
		}
		return result
	}

	private func readNPairs(_ n: Int) throws -> [CBOR : CBOR] {
		var result : [CBOR : CBOR] = [:]
		for _ in (0..<n) {
			guard let key  = try decodeItem() else { throw CBORError.unfinishedSequence }
			guard let val  = try decodeItem() else { throw CBORError.unfinishedSequence }
			result[key] = val
		}
		return result
	}

	private func readPairsUntilBreak() throws -> [CBOR : CBOR] {
		var result : [CBOR : CBOR] = [:]
		var key = try decodeItem()
		var val = try decodeItem()
		while (key != CBOR.break) {
			guard let okey = key else { throw CBORError.unfinishedSequence }
			guard let oval = val else { throw CBORError.unfinishedSequence }
			result[okey] = oval
			do { key = try decodeItem() } catch CBORError.unfinishedSequence { key = nil }
			guard (key != CBOR.break) else { break } // don't eat the val after the break!
			do { val = try decodeItem() } catch CBORError.unfinishedSequence { val = nil }
		}
		return result
	}

	public func decodeItem() throws -> CBOR? {
		switch try istream.popByte() {
		case let b where b <= 0x17: return CBOR.unsignedInt(UInt(b))
		case 0x18: return CBOR.unsignedInt(UInt(try istream.popByte()))
		case 0x19: return CBOR.unsignedInt(UInt(try readUInt(2) as UInt16))
		case 0x1a: return CBOR.unsignedInt(UInt(try readUInt(4) as UInt32))
		case 0x1b: return CBOR.unsignedInt(UInt(try readUInt(8) as UInt64))

		case let b where 0x20 <= b && b <= 0x37: return CBOR.negativeInt(UInt(b - 0x20))
		case 0x38: return CBOR.negativeInt(UInt(try istream.popByte()))
		case 0x39: return CBOR.negativeInt(UInt(try readUInt(2) as UInt16))
		case 0x3a: return CBOR.negativeInt(UInt(try readUInt(4) as UInt32))
		case 0x3b: return CBOR.negativeInt(UInt(try readUInt(8) as UInt64))

		case let b where 0x40 <= b && b <= 0x57: return CBOR.byteString(Array(try istream.popBytes(Int(b - 0x40))))
		case 0x58:
			let numBytes: Int = Int(try istream.popByte())
			return CBOR.byteString(Array(try istream.popBytes(numBytes)))
		case 0x59:
			let numBytes: Int = Int(try readUInt(2) as UInt16)
			return CBOR.byteString(Array(try istream.popBytes(numBytes)))
		case 0x5a:
			let numBytes: Int = Int(try readUInt(4) as UInt32)
			return CBOR.byteString(Array(try istream.popBytes(numBytes)))
		case 0x5b:
			let numBytes: Int = Int(try readUInt(8) as UInt64)
			return CBOR.byteString(Array(try istream.popBytes(numBytes)))
		case 0x5f: return CBOR.byteString(try readUntilBreak().flatMap { x -> [UInt8] in guard case .byteString(let r) = x else { throw CBORError.wrongTypeInsideSequence }; return r })

		case let b where 0x60 <= b && b <= 0x77: return CBOR.utf8String(try Util.decodeUtf8(try istream.popBytes(Int(b - 0x60))))
		case 0x78:
			let numBytes: Int = Int(try istream.popByte())
			return CBOR.utf8String(try Util.decodeUtf8(try istream.popBytes(numBytes)))
		case 0x79:
			let numBytes: Int = Int(try readUInt(2) as UInt16)
			return CBOR.utf8String(try Util.decodeUtf8(try istream.popBytes(numBytes)))
		case 0x7a:
			let numBytes: Int = Int(try readUInt(4) as UInt32)
			return CBOR.utf8String(try Util.decodeUtf8(try istream.popBytes(numBytes)))
		case 0x7b:
			let numBytes: Int = Int(try readUInt(8) as UInt64)
			return CBOR.utf8String(try Util.decodeUtf8(try istream.popBytes(numBytes)))
		case 0x7f: return CBOR.utf8String(try readUntilBreak().map { x -> String in guard case .utf8String(let r) = x else { throw CBORError.wrongTypeInsideSequence }; return r }.joined(separator: ""))

		case let b where 0x80 <= b && b <= 0x97: return CBOR.array(try readN(Int(b - 0x80)))
		case 0x98: return CBOR.array(try readN(Int(try istream.popByte())))
		case 0x99:
			let numBytes: Int = Int(try readUInt(2) as UInt16)
			return CBOR.array(try readN(numBytes))
		case 0x9a:
			let numBytes: Int = Int(try readUInt(4) as UInt32)
			return CBOR.array(try readN(numBytes))
		case 0x9b:
			let numBytes: Int = Int(try readUInt(8) as UInt64)
			return CBOR.array(try readN(numBytes))
		case 0x9f: return CBOR.array(try readUntilBreak())

		case let b where 0xa0 <= b && b <= 0xb7: return CBOR.map(try readNPairs(Int(b - 0xa0)))
		case 0xb8:
			let numBytes: Int = Int(try istream.popByte())
			return CBOR.map(try readNPairs(numBytes))
		case 0xb9:
			let numBytes: Int = Int(try readUInt(2) as UInt16)
			return CBOR.map(try readNPairs(numBytes))
		case 0xba:
			let numBytes: Int = Int(try readUInt(4) as UInt32)
			return CBOR.map(try readNPairs(numBytes))
		case 0xbb:
			let numBytes: Int = Int(try readUInt(8) as UInt64)
			return CBOR.map(try readNPairs(numBytes))
		case 0xbf: return CBOR.map(try readPairsUntilBreak())

		case let b where 0xc0 <= b && b <= 0xd7:
			guard let item = try decodeItem() else { throw CBORError.unfinishedSequence }
			return CBOR.tagged(UInt8(b - 0xc0), item)
		case 0xd8:
			let tag = UInt8(try istream.popByte())
			guard let item = try decodeItem() else { throw CBORError.unfinishedSequence }
			return CBOR.tagged(tag, item)
		case 0xd9:
			let tag = UInt8(try readUInt(2) as UInt16)
			guard let item = try decodeItem() else { throw CBORError.unfinishedSequence }
			return CBOR.tagged(tag, item)
		case 0xda:
			let tag = UInt8(try readUInt(4) as UInt32)
			guard let item = try decodeItem() else { throw CBORError.unfinishedSequence }
			return CBOR.tagged(tag, item)
		case 0xdb:
			let tag = UInt8(try readUInt(8) as UInt64)
			guard let item = try decodeItem() else { throw CBORError.unfinishedSequence }
			return CBOR.tagged(tag, item)

		case let b where 0xe0 <= b && b <= 0xf3: return CBOR.simple(b - 0xe0)
		case 0xf4: return CBOR.boolean(false)
		case 0xf5: return CBOR.boolean(true)
		case 0xf6: return CBOR.null
		case 0xf7: return CBOR.undefined
		case 0xf8: return CBOR.simple(try istream.popByte())

		case 0xf9:
            let ptr = UnsafeRawPointer(Array(try istream.popBytes(2).reversed())).bindMemory(to: UInt16.self, capacity: 1)
            return CBOR.half(loadFromF16(ptr))
		case 0xfa:
            return CBOR.float(UnsafeRawPointer(Array(try istream.popBytes(4).reversed())).load(as: Float32.self))
		case 0xfb:
            return CBOR.double(UnsafeRawPointer(Array(try istream.popBytes(8).reversed())).load(as: Float64.self))

		case 0xff: return CBOR.break
		default: return nil
		}
	}

}
