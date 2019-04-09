struct AnyCodingKey: CodingKey, Equatable {
    var stringValue: String
    var intValue: Int?

    init?(stringValue: String) {
        self.stringValue = stringValue
        self.intValue = nil
    }

    init?(intValue: Int) {
        self.stringValue = "\(intValue)"
        self.intValue = intValue
    }

    init<Key: CodingKey>(_ base: Key) {
        if let intValue = base.intValue {
            self.init(intValue: intValue)!
        } else {
            self.init(stringValue: base.stringValue)!
        }
    }
}

extension AnyCodingKey: Hashable {
    public func hash(into hasher: inout Hasher) {
        self.intValue?.hash(into: &hasher) ?? self.stringValue.hash(into: &hasher)
    }
}
