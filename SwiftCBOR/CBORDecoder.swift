enum CBORError : ErrorType {
	case UnfinishedSequence
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
	
	private func readUntilBreak() throws -> [Any] {
		var result : [Any] = []
		var cur = try decodeItem()
		while ((cur as? CBORBreak) == nil) {
			if let curr = cur {
				result.append(curr)
			} else {
				throw CBORError.UnfinishedSequence
			}
			cur = try decodeItem()
		}
		return result
	}
	
	private func readN(n: Int) throws -> [Any] {
		return try (0..<n).map { _ in guard let r = try decodeItem() else { throw CBORError.UnfinishedSequence }; return r }
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

		case 0xff: return CBORBreak()
		default: return nil
		}
	}
	
}