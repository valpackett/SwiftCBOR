public enum CBOR : Equatable, Hashable {
	case PositiveInt(UInt)
	case NegativeInt(UInt)
	case ByteString([UInt8])
	case UTF8String(String)
	case Array([CBOR])
	case Map([CBOR : CBOR])
	case Break
	
	public var hashValue : Int {
		switch self {
		case let .PositiveInt(l): return l.hashValue
		case let .NegativeInt(l): return l.hashValue
		case let .ByteString(l):  return Util.djb2Hash(l.map { Int($0) })
		case let .UTF8String(l):  return l.hashValue
		case let .Array(l):	      return Util.djb2Hash(l.map { $0.hashValue })
		case let .Map(l):         return Util.djb2Hash(l.map { $0.hashValue &+ $1.hashValue })
		default:                  return 0
		}
	}
}

public func ==(lhs: CBOR, rhs: CBOR) -> Bool {
	switch (lhs, rhs) {
	case (let .PositiveInt(l), let .PositiveInt(r)): return l == r
	case (let .NegativeInt(l), let .NegativeInt(r)): return l == r
	case (let .ByteString(l),  let .ByteString(r)):  return l == r
	case (let .UTF8String(l),  let .UTF8String(r)):  return l == r
	case (let .Array(l),       let .Array(r)):       return l == r
	case (let .Map(l),         let .Map(r)):         return l == r
	case (.Break, .Break):                           return true
	default:                                         return false
	}
}