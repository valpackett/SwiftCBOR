/// An ordered map of CBOR values.
///
/// A map is an unordered collection in the CBOR data model, so two maps that hold the same
/// entries are equal whatever order their keys are in. The order that the keys were added
/// in is kept, so that a map that is decoded and encoded again keeps the order it arrived
/// in.
public struct CBORMap: Equatable, Hashable, ExpressibleByDictionaryLiteral {
    public private(set) var keys: [CBOR]
    private var values: [CBOR: CBOR]

    public init() {
        self.keys = []
        self.values = [:]
    }

    public init(dictionaryLiteral elements: (CBOR, CBOR)...) {
        self.init()
        for (key, value) in elements {
            self[key] = value
        }
    }

    /// Creates a map from a dictionary. The order of the keys of a dictionary is not defined,
    /// so the order of the keys of the map is not defined either.
    public init(_ dictionary: [CBOR: CBOR]) {
        self.init()
        for (key, value) in dictionary {
            self[key] = value
        }
    }

    /// Creates a map from the given pairs, in order.
    public init(_ pairs: [(CBOR, CBOR)]) {
        self.init()
        for (key, value) in pairs {
            self[key] = value
        }
    }

    public var count: Int { self.keys.count }

    public var isEmpty: Bool { self.keys.isEmpty }

    /// The entries of the map, in order.
    public var pairs: [(key: CBOR, value: CBOR)] {
        self.keys.map { (key: $0, value: self.values[$0]!) }
    }

    /// The value for a key, or nil if the map does not hold it.
    ///
    /// Setting a value for a key that the map already holds replaces the value and leaves
    /// the key where it is. Setting nil removes the key.
    public subscript(key: CBOR) -> CBOR? {
        get { self.values[key] }
        set {
            if let newValue = newValue {
                if self.values.updateValue(newValue, forKey: key) == nil {
                    self.keys.append(key)
                }
            } else if self.values.removeValue(forKey: key) != nil {
                self.keys.removeAll { $0 == key }
            }
        }
    }

    public func forEach(_ body: (CBOR, CBOR) throws -> Void) rethrows {
        for key in self.keys {
            try body(key, self.values[key]!)
        }
    }

    /// Two maps are equal when they hold the same entries, whatever order their keys are in.
    public static func == (lhs: CBORMap, rhs: CBORMap) -> Bool {
        lhs.count == rhs.count && lhs.keys.allSatisfy { lhs.values[$0] == rhs.values[$0] }
    }

    /// The hash does not depend on the order of the keys, to match the equality.
    public func hash(into hasher: inout Hasher) {
        var combined = 0
        for key in self.keys {
            combined ^= key.hashValue &+ self.values[key]!.hashValue
        }
        combined.hash(into: &hasher)
    }
}
