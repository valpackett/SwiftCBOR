enum CBORError : ErrorType {
	case UnfinishedSequence
}

class LargeNegativeInt {
	let i: UInt
	
	init(i: UInt) { self.i = i }
}

class CBORDecoder {
	
	var buffer : ArraySlice<UInt8>
	
	init(input: ArraySlice<UInt8>) {
		buffer = input
	}
	
	func popBytes(n: Int) throws -> ArraySlice<UInt8> {
		if buffer.count < n { throw CBORError.UnfinishedSequence }
		let result = buffer.prefix(n)
		buffer = buffer.dropFirst(n)
		return result
	}
	
	func decodeItem() throws -> AnyObject? {
		switch buffer.removeFirst() {
		case let b where b <= 0x17: return UInt(b)
		case 0x18: return UInt(buffer.removeFirst())
		case 0x19: return UInt(UnsafePointer<UInt16>(Array(try popBytes(2)).reverse()).memory)
		case 0x1a: return UInt(UnsafePointer<UInt32>(Array(try popBytes(4)).reverse()).memory)
		case 0x1b: return UInt(UnsafePointer<UInt64>(Array(try popBytes(8)).reverse()).memory)
		case let b where 0x20 <= b && b <= 0x37: return -1 - Int(b - 0x20)
		case 0x38: return -1 - Int(buffer.removeFirst())
		case 0x39: return -1 - Int(UnsafePointer<UInt16>(Array(try popBytes(2)).reverse()).memory)
		case 0x3a: return -1 - Int(UnsafePointer<UInt32>(Array(try popBytes(4)).reverse()).memory)
		case 0x3b: return LargeNegativeInt(i: UInt(UnsafePointer<UInt64>(Array(try popBytes(8)).reverse()).memory))
		default: return nil
		}
	}
	
}