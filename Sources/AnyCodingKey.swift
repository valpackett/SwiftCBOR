struct AnyCodingKey: CodingKey, Equatable {
    var stringValue: String {
        get { self._stringValue ?? "_do_not_use_this_string_value_use_the_int_value_instead_" }
    }

    var _stringValue: String?
    var intValue: Int?

    init(stringValue: String) {
        self._stringValue = stringValue
        self.intValue = nil
    }

    init(intValue: Int) {
        self.intValue = intValue
        self._stringValue = nil
    }

    init<Key: CodingKey>(_ base: Key, useStringKey: Bool = false) {
        if !useStringKey, let intValue = base.intValue {
            self.init(intValue: intValue)
        } else {
            self.init(stringValue: base.stringValue)
        }
    }

    func key<K: CodingKey>() -> K {
        if let intValue = self.intValue {
            guard let key = K(intValue: intValue) else {
                preconditionFailure("CodingKey \(K.self) failed to initialize with intValue: \(intValue)")
            }
            return key
        } else if let stringValue = self._stringValue {
            guard let key = K(stringValue: stringValue) else {
                preconditionFailure("CodingKey \(K.self) failed to initialize with stringValue: \(stringValue)")
            }
            return key
        } else {
            preconditionFailure("AnyCodingKey created without a string or int value")
        }
    }
}

extension AnyCodingKey: Hashable {
    public func hash(into hasher: inout Hasher) {
        self.intValue?.hash(into: &hasher) ?? self._stringValue?.hash(into: &hasher)
    }
}

extension AnyCodingKey: Encodable {
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        if let intValue = self.intValue {
            try container.encode(intValue)
        } else if let stringValue = self._stringValue {
            try container.encode(stringValue)
        } else {
            throw EncodingError.invalidValue(
                self,
                EncodingError.Context(
                    codingPath: encoder.codingPath,
                    debugDescription: "AnyCodingKey created without a string or int value"
                )
            )
        }
    }
}

extension AnyCodingKey: Decodable {
    init(from decoder: Decoder) throws {
        let value = try decoder.singleValueContainer()
        if let intValue = try? value.decode(Int.self) {
            self._stringValue = nil
            self.intValue = intValue
        } else if let stringValue = try? value.decode(String.self) {
            self._stringValue = stringValue
            self.intValue = nil
        } else {
            throw DecodingError.typeMismatch(
                AnyCodingKey.self,
                DecodingError.Context(
                    codingPath: decoder.codingPath,
                    debugDescription: "Expected Int or String key"
                )
            )
        }
    }
}
