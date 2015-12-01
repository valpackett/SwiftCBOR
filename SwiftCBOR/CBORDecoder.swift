public enum CBORError : ErrorType {
	case UnfinishedSequence
	case WrongTypeInsideSequence
	case IncorrectUTF8String
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
		istream = ArraySliceUInt8(slice: input[0..<input.count])
	}

	private func readUInt<T: UnsignedIntegerType>(n: Int) throws -> T {
		return UnsafePointer<T>(Array(try istream.popBytes(n)).reverse()).memory
	}

	private func readN(n: Int) throws -> [CBOR] {
		return try (0..<n).map { _ in guard let r = try decodeItem() else { throw CBORError.UnfinishedSequence }; return r }
	}

	private func readUntilBreak() throws -> [CBOR] {
		var result : [CBOR] = []
		var cur = try decodeItem()
		while (cur != CBOR.Break) {
			guard let curr = cur else { throw CBORError.UnfinishedSequence }
			result.append(curr)
			cur = try decodeItem()
		}
		return result
	}

	private func readNPairs(n: Int) throws -> [CBOR : CBOR] {
		var result : [CBOR : CBOR] = [:]
		for _ in (0..<n) {
			guard let key  = try decodeItem() else { throw CBORError.UnfinishedSequence }
			guard let val  = try decodeItem() else { throw CBORError.UnfinishedSequence }
			result[key] = val
		}
		return result
	}

	private func readPairsUntilBreak() throws -> [CBOR : CBOR] {
		var result : [CBOR : CBOR] = [:]
		var key = try decodeItem()
		var val = try decodeItem()
		while (key != CBOR.Break) {
			guard let okey = key else { throw CBORError.UnfinishedSequence }
			guard let oval = val else { throw CBORError.UnfinishedSequence }
			result[okey] = oval
			do { key = try decodeItem() } catch CBORError.UnfinishedSequence { key = nil }
			guard (key != CBOR.Break) else { break } // don't eat the val after the break!
			do { val = try decodeItem() } catch CBORError.UnfinishedSequence { val = nil }
		}
		return result
	}

	public func decodeItem() throws -> CBOR? {
		switch try istream.popByte() {
		case let b where b <= 0x17: return CBOR.UnsignedInt(UInt(b))
		case 0x18: return CBOR.UnsignedInt(UInt(try istream.popByte()))
		case 0x19: return CBOR.UnsignedInt(UInt(try readUInt(2) as UInt16))
		case 0x1a: return CBOR.UnsignedInt(UInt(try readUInt(4) as UInt32))
		case 0x1b: return CBOR.UnsignedInt(UInt(try readUInt(8) as UInt64))

		case let b where 0x20 <= b && b <= 0x37: return CBOR.NegativeInt(UInt(b - 0x20))
		case 0x38: return CBOR.NegativeInt(UInt(try istream.popByte()))
		case 0x39: return CBOR.NegativeInt(UInt(try readUInt(2) as UInt16))
		case 0x3a: return CBOR.NegativeInt(UInt(try readUInt(4) as UInt32))
		case 0x3b: return CBOR.NegativeInt(UInt(try readUInt(8) as UInt64))

		case let b where 0x40 <= b && b <= 0x57: return CBOR.ByteString(Array(try istream.popBytes(Int(b - 0x40))))
		case 0x58: return CBOR.ByteString(Array(try istream.popBytes(Int(try istream.popByte()))))
		case 0x59: return CBOR.ByteString(Array(try istream.popBytes(Int(try readUInt(2) as UInt16))))
		case 0x5a: return CBOR.ByteString(Array(try istream.popBytes(Int(try readUInt(4) as UInt32))))
		case 0x5b: return CBOR.ByteString(Array(try istream.popBytes(Int(try readUInt(8) as UInt64))))
		case 0x5f: return CBOR.ByteString(try readUntilBreak().flatMap { x -> [UInt8] in guard case .ByteString(let r) = x else { throw CBORError.WrongTypeInsideSequence }; return r })

		case let b where 0x60 <= b && b <= 0x77: return CBOR.UTF8String(try Util.decodeUtf8(try istream.popBytes(Int(b - 0x60))))
		case 0x78: return CBOR.UTF8String(try Util.decodeUtf8(try istream.popBytes(Int(try istream.popByte()))))
		case 0x79: return CBOR.UTF8String(try Util.decodeUtf8(try istream.popBytes(Int(try readUInt(2) as UInt16))))
		case 0x7a: return CBOR.UTF8String(try Util.decodeUtf8(try istream.popBytes(Int(try readUInt(4) as UInt32))))
		case 0x7b: return CBOR.UTF8String(try Util.decodeUtf8(try istream.popBytes(Int(try readUInt(8) as UInt64))))
		case 0x7f: return CBOR.UTF8String(try readUntilBreak().map { x -> String in guard case .UTF8String(let r) = x else { throw CBORError.WrongTypeInsideSequence }; return r }.joinWithSeparator(""))

		case let b where 0x80 <= b && b <= 0x97: return CBOR.Array(try readN(Int(b - 0x80)))
		case 0x98: return CBOR.Array(try readN(Int(try istream.popByte())))
		case 0x99: return CBOR.Array(try readN(Int(try readUInt(2) as UInt16)))
		case 0x9a: return CBOR.Array(try readN(Int(try readUInt(4) as UInt32)))
		case 0x9b: return CBOR.Array(try readN(Int(try readUInt(8) as UInt64)))
		case 0x9f: return CBOR.Array(try readUntilBreak())

		case let b where 0xa0 <= b && b <= 0xb7: return CBOR.Map(try readNPairs(Int(b - 0xa0)))
		case 0xb8: return CBOR.Map(try readNPairs(Int(try istream.popByte())))
		case 0xb9: return CBOR.Map(try readNPairs(Int(try readUInt(2) as UInt16)))
		case 0xba: return CBOR.Map(try readNPairs(Int(try readUInt(4) as UInt32)))
		case 0xbb: return CBOR.Map(try readNPairs(Int(try readUInt(8) as UInt64)))
		case 0xbf: return CBOR.Map(try readPairsUntilBreak())

		case let b where 0xc0 <= b && b <= 0xd7:
			guard let item = try decodeItem() else { throw CBORError.UnfinishedSequence }
			return CBOR.Tagged(UInt(b - 0xc0), item)
		case 0xd8:
			let tag = UInt(try istream.popByte())
			guard let item = try decodeItem() else { throw CBORError.UnfinishedSequence }
			return CBOR.Tagged(tag, item)
		case 0xd9:
			let tag = UInt(try readUInt(2) as UInt16)
			guard let item = try decodeItem() else { throw CBORError.UnfinishedSequence }
			return CBOR.Tagged(tag, item)
		case 0xda:
			let tag = UInt(try readUInt(4) as UInt32)
			guard let item = try decodeItem() else { throw CBORError.UnfinishedSequence }
			return CBOR.Tagged(tag, item)
		case 0xdb:
			let tag = UInt(try readUInt(8) as UInt64)
			guard let item = try decodeItem() else { throw CBORError.UnfinishedSequence }
			return CBOR.Tagged(tag, item)

		case let b where 0xe0 <= b && b <= 0xf3: return CBOR.Simple(b - 0xe0)
		case 0xf4: return CBOR.Boolean(false)
		case 0xf5: return CBOR.Boolean(true)
		case 0xf6: return CBOR.Null
		case 0xf7: return CBOR.Undefined
		case 0xf8: return CBOR.Simple(try istream.popByte())

		case 0xf9: return CBOR.Half(loadFromF16(UnsafePointer<UInt16>(Array(try istream.popBytes(2)).reverse())))
		case 0xfa: return CBOR.Float(UnsafePointer<Float32>(Array(try istream.popBytes(4)).reverse()).memory)
		case 0xfb: return CBOR.Double(UnsafePointer<Float64>(Array(try istream.popBytes(8)).reverse()).memory)

		case 0xff: return CBOR.Break
		default: return nil
		}
	}

}