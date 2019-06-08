
struct AnyCodingKey: CodingKey, Equatable, Hashable {
    var stringValue: String
    var intValue: Int?

    init?(stringValue: String) {
        self.stringValue = stringValue
        self.intValue = nil
    }

    init(intValue: Int) {
        self.stringValue = "\(intValue)"
        self.intValue = intValue
    }

    init(stringValue: String, intValue: Int?) {
        self.stringValue = stringValue
        self.intValue = intValue
    }

    init(index: Int) {
        self.stringValue = "Index \(index)"
        self.intValue = index
    }

    init<Key: CodingKey>(_ base: Key) {
        if let index = base.intValue {
            self.init(intValue: index)
        } else {
            self.init(stringValue: base.stringValue)!
        }
    }

    func key<K: CodingKey>() -> K {
        if let intValue = self.intValue {
            return K(intValue: intValue)!
        } else {
            return K(stringValue: self.stringValue)!
        }
    }

    internal static let `super` = AnyCodingKey(stringValue: "super")!

}

extension AnyCodingKey: Encodable {
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        if let intValue = self.intValue {
            try container.encode(intValue)
        } else {
            try container.encode(self.stringValue)
        }
    }
}

extension AnyCodingKey: Decodable {
    init(from decoder: Decoder) throws {
        let value = try decoder.singleValueContainer()
        if let intValue = try? value.decode(Int.self) {
            self.stringValue = "\(intValue)"
            self.intValue = intValue
        } else {
            self.stringValue = try! value.decode(String.self)
            self.intValue = nil
        }
    }
}
