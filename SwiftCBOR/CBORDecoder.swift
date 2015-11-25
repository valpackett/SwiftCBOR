enum CBORError : ErrorType {
	case UnfinishedSequence
	case UnsupportedMapKeyType
	case WrongTypeInsideSequence
	case IncorrectUTF8String
}

struct LargeNegativeInt {
	let i: UInt

	init(i: UInt) { self.i = i }
}

internal struct CBORBreak {}

final class CBORDecoder {

	private var istream : CBORInputStream

	init(input: ArraySlice<UInt8>) {
		istream = ArraySliceUInt8(slice: input)
	}

	init(stream: CBORInputStream) {
		istream = stream
	}

	private func readUInt<T: UnsignedIntegerType>(n: Int) throws -> T {
		return UnsafePointer<T>(Array(try istream.popBytes(n)).reverse()).memory
	}

	private func readN(n: Int) throws -> [Any] {
		return try (0..<n).map { _ in guard let r = try decodeItem() else { throw CBORError.UnfinishedSequence }; return r }
	}

	private func readUntilBreak() throws -> [Any] {
		var result : [Any] = []
		var cur = try decodeItem()
		while ((cur as? CBORBreak) == nil) {
			guard let curr = cur else { throw CBORError.UnfinishedSequence }
			result.append(curr)
			cur = try decodeItem()
		}
		return result
	}

	private func readNPairs(n: Int) throws -> [String : Any] {
		var result : [String : Any] = [:]
		for _ in (0..<n) {
			guard let key  = try decodeItem() else { throw CBORError.UnfinishedSequence }
			guard let skey = key as? String   else { throw CBORError.UnsupportedMapKeyType }
			guard let val  = try decodeItem() else { throw CBORError.UnfinishedSequence }
			result[skey] = val
		}
		return result
	}

	private func readPairsUntilBreak() throws -> [String : Any] {
		var result : [String : Any] = [:]
		var key = try decodeItem()
		var val = try decodeItem()
		while ((key as? CBORBreak) == nil) {
			guard let okey = key else { throw CBORError.UnfinishedSequence }
			guard let skey = okey as? String else { throw CBORError.UnsupportedMapKeyType }
			guard let oval = val else { throw CBORError.UnfinishedSequence }
			result[skey] = oval
			do { key = try decodeItem() } catch CBORError.UnfinishedSequence { key = nil }
			guard ((key as? CBORBreak) == nil) else { break } // don't eat the val after the break!
			do { val = try decodeItem() } catch CBORError.UnfinishedSequence { val = nil }
		}
		return result
	}

	func decodeItem() throws -> Any? {
		switch try istream.popByte() {
		case let b where b <= 0x17: return UInt(b)
		case 0x18: return UInt(try istream.popByte())
		case 0x19: return UInt(try readUInt(2) as UInt16)
		case 0x1a: return UInt(try readUInt(4) as UInt32)
		case 0x1b: return UInt(try readUInt(8) as UInt64)

		case let b where 0x20 <= b && b <= 0x37: return -1 - Int(b - 0x20)
		case 0x38: return -1 - Int(try istream.popByte())
		case 0x39: return -1 - Int(try readUInt(2) as UInt16)
		case 0x3a: return -1 - Int(try readUInt(4) as UInt32)
		case 0x3b: return LargeNegativeInt(i: UInt(try readUInt(8) as UInt64))

		case let b where 0x40 <= b && b <= 0x57: return Array(try istream.popBytes(Int(b - 0x40)))
		case 0x58: return Array(try istream.popBytes(Int(try istream.popByte())))
		case 0x59: return Array(try istream.popBytes(Int(try readUInt(2) as UInt16)))
		case 0x5a: return Array(try istream.popBytes(Int(try readUInt(4) as UInt32)))
		case 0x5b: return Array(try istream.popBytes(Int(try readUInt(8) as UInt64)))
		case 0x5f: return try readUntilBreak().flatMap { x -> [UInt8] in guard let r = x as? [UInt8] else { throw CBORError.WrongTypeInsideSequence }; return r }

		case let b where 0x60 <= b && b <= 0x77: return try Util.decodeUtf8(try istream.popBytes(Int(b - 0x60)))
		case 0x78: return try Util.decodeUtf8(try istream.popBytes(Int(try istream.popByte())))
		case 0x79: return try Util.decodeUtf8(try istream.popBytes(Int(try readUInt(2) as UInt16)))
		case 0x7a: return try Util.decodeUtf8(try istream.popBytes(Int(try readUInt(4) as UInt32)))
		case 0x7b: return try Util.decodeUtf8(try istream.popBytes(Int(try readUInt(8) as UInt64)))
		case 0x7f: return try readUntilBreak().map { x -> String in guard let r = x as? String else { throw CBORError.WrongTypeInsideSequence }; return r }.joinWithSeparator("")

		case let b where 0x80 <= b && b <= 0x97: return try readN(Int(b - 0x80))
		case 0x98: return try readN(Int(try istream.popByte()))
		case 0x99: return try readN(Int(try readUInt(2) as UInt16))
		case 0x9a: return try readN(Int(try readUInt(4) as UInt32))
		case 0x9b: return try readN(Int(try readUInt(8) as UInt64))
		case 0x9f: return try readUntilBreak()

		case let b where 0xa0 <= b && b <= 0xb7: return try readNPairs(Int(b - 0xa0))
		case 0xb8: return try readNPairs(Int(try istream.popByte()))
		case 0xb9: return try readNPairs(Int(try readUInt(2) as UInt16))
		case 0xba: return try readNPairs(Int(try readUInt(4) as UInt32))
		case 0xbb: return try readNPairs(Int(try readUInt(8) as UInt64))
		case 0xbf: return try readPairsUntilBreak()

		case 0xff: return CBORBreak()
		default: return nil
		}
	}

}