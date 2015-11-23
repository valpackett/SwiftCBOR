enum CBORError : ErrorType {
	case UnfinishedSequence
	case WrongTypeInsideSequence
}

struct LargeNegativeInt {
	let i: UInt
	
	init(i: UInt) { self.i = i }
}

struct CBORBreak {}

class CBORDecoder {
	
	var buffer : ArraySlice<UInt8>
	
	init(input: ArraySlice<UInt8>) {
		buffer = input
	}
	
	private func popBytes(n: Int) throws -> ArraySlice<UInt8> {
		if buffer.count < n { throw CBORError.UnfinishedSequence }
		let result = buffer.prefix(n)
		buffer = buffer.dropFirst(n)
		return result
	}
	
	private func readUInt<T: UnsignedIntegerType>(n: Int) throws -> T {
		return UnsafePointer<T>(Array(try popBytes(n)).reverse()).memory
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
	
	func decodeItem() throws -> Any? {
		switch buffer.removeFirst() {
		case let b where b <= 0x17: return UInt(b)
		case 0x18: return UInt(buffer.removeFirst())
		case 0x19: return UInt(try readUInt(2) as UInt16)
		case 0x1a: return UInt(try readUInt(4) as UInt32)
		case 0x1b: return UInt(try readUInt(8) as UInt64)
		
		case let b where 0x20 <= b && b <= 0x37: return -1 - Int(b - 0x20)
		case 0x38: return -1 - Int(buffer.removeFirst())
		case 0x39: return -1 - Int(try readUInt(2) as UInt16)
		case 0x3a: return -1 - Int(try readUInt(4) as UInt32)
		case 0x3b: return LargeNegativeInt(i: UInt(try readUInt(8) as UInt64))
		
		case let b where 0x40 <= b && b <= 0x57: return Array(try popBytes(Int(b - 0x40)))
		case 0x58: return Array(try popBytes(Int(buffer.removeFirst())))
		case 0x59: return Array(try popBytes(Int(try readUInt(2) as UInt16)))
		case 0x5a: return Array(try popBytes(Int(try readUInt(4) as UInt32)))
		case 0x5b: return Array(try popBytes(Int(try readUInt(8) as UInt64)))
		case 0x5f: return try readUntilBreak().flatMap { x -> [UInt8] in guard let r = x as? [UInt8] else { throw CBORError.WrongTypeInsideSequence }; return r }
		
		case 0xff: return CBORBreak()
		default: return nil
		}
	}
	
}