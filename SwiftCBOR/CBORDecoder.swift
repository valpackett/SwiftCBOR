enum CBORError : ErrorType {
	case UnfinishedSequence
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
		case let b where b < 0x17: return UInt(b)
		case 0x18: return UInt(buffer.removeFirst())
		case 0x19: return UInt(UnsafePointer<UInt16>(Array(try popBytes(2))).memory)
		case 0x1a: return UInt(UnsafePointer<UInt32>(Array(try popBytes(4))).memory)
		case 0x1b: return UInt(UnsafePointer<UInt64>(Array(try popBytes(8))).memory)
		default: return nil
		}
	}
	
}