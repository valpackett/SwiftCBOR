

public indirect enum CBOR : Equatable, Hashable,
	ExpressibleByNilLiteral, ExpressibleByIntegerLiteral, ExpressibleByStringLiteral,
	ExpressibleByArrayLiteral, ExpressibleByDictionaryLiteral, ExpressibleByBooleanLiteral,
	ExpressibleByFloatLiteral {
	case unsignedInt(UInt)
	case negativeInt(UInt)
	case byteString([UInt8])
	case utf8String(String)
	case array([CBOR])
	case map([CBOR : CBOR])
	case tagged(UInt8, CBOR)
	case simple(UInt8)
	case boolean(Bool)
	case null
	case undefined
	case half(Float32)
	case float(Float32)
	case double(Float64)
	case `break`

	public var hashValue : Int {
		switch self {
		case let .unsignedInt(l): return l.hashValue
		case let .negativeInt(l): return l.hashValue
		case let .byteString(l):  return Util.djb2Hash(l.map { Int($0) })
		case let .utf8String(l):  return l.hashValue
		case let .array(l):	      return Util.djb2Hash(l.map { $0.hashValue })
		case let .map(l):         return Util.djb2Hash(l.map { $0.hashValue &+ $1.hashValue })
		case let .tagged(t, l):   return t.hashValue &+ l.hashValue
		case let .simple(l):      return l.hashValue
		case let .boolean(l):     return l.hashValue
		case .null:                return -1
		case .undefined:           return -2
		case let .half(l):        return l.hashValue
		case let .float(l):       return l.hashValue
		case let .double(l):      return l.hashValue
		case .break:               return Int.min
		}
	}
	
	public subscript(position: CBOR) -> CBOR? {
		get {
			switch (self, position) {
			case (let .array(l), let .unsignedInt(i)): return l[Int(i)]
			case (let .map(l), let i): return l[i]
			default: return nil
			}
		}
		set(x) {
			switch (self, position) {
			case (var .array(l), let .unsignedInt(i)): l[Int(i)] = x!
			case (var .map(l), let i): l[i] = x!
			default: break
			}
		}
	}

	public init(nilLiteral: ()) { self = .null }
	public init(integerLiteral value: Int) {
		if value < 0 { self = .negativeInt(UInt(-value) - 1) } else { self = .unsignedInt(UInt(value)) }
	}
	public init(extendedGraphemeClusterLiteral value: String) { self = .utf8String(value) }
	public init(unicodeScalarLiteral value: String) { self = .utf8String(value) }
	public init(stringLiteral value: String) { self = .utf8String(value) }
	public init(arrayLiteral elements: CBOR...) { self = .array(elements) }
	public init(dictionaryLiteral elements: (CBOR, CBOR)...) {
		var result = [CBOR : CBOR]()
		for (key, value) in elements {
			result[key] = value
		}
		self = .map(result)
	}
	public init(booleanLiteral value: Bool) { self = .boolean(value) }
	public init(floatLiteral value: Float32) { self = .float(value) }
}

public func ==(lhs: CBOR, rhs: CBOR) -> Bool {
	switch (lhs, rhs) {
	case (let .unsignedInt(l), let .unsignedInt(r)): return l == r
	case (let .negativeInt(l), let .negativeInt(r)): return l == r
	case (let .byteString(l),  let .byteString(r)):  return l == r
	case (let .utf8String(l),  let .utf8String(r)):  return l == r
	case (let .array(l),       let .array(r)):       return l == r
	case (let .map(l),         let .map(r)):         return l == r
	case (let .tagged(tl, l),  let .tagged(tr, r)):  return tl == tr && l == r
	case (let .simple(l),      let .simple(r)):      return l == r
	case (let .boolean(l),     let .boolean(r)):     return l == r
	case (.null,               .null):               return true
	case (.undefined,          .undefined):          return true
	case (let .half(l),        let .half(r)):        return l == r
	case (let .float(l),       let .float(r)):       return l == r
	case (let .double(l),      let .double(r)):      return l == r
	case (.break,              .break):              return true
	default:                                         return false
	}
}
