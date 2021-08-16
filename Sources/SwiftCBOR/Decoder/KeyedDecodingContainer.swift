import Foundation

extension _CBORDecoder {
    final class KeyedContainer<Key: CodingKey> {
        private var cachedNestedContainers: [AnyCodingKey: CBORDecodingContainer]?
        func getNestedContainers() throws -> [AnyCodingKey: CBORDecodingContainer] {
            if let cachedNestedContainers = cachedNestedContainers {
                return cachedNestedContainers
            }
            guard let count = self.count else {
                return [:]
            }

            var nestedContainers: [AnyCodingKey: CBORDecodingContainer] = [:]

            let unkeyedContainer = UnkeyedContainer(data: self.data.suffix(from: self.index), codingPath: self.codingPath, userInfo: self.userInfo)
            unkeyedContainer.count = count * 2

            var iterator = try unkeyedContainer.getNestedContainers().makeIterator()

            for _ in 0..<count {
                guard let keyContainer = iterator.next() as? _CBORDecoder.SingleValueContainer,
                    let container = iterator.next() else {
                        fatalError() // FIXME
                }

                let keyVal = try keyContainer.decode(AnyCodingKey.self)
                nestedContainers[keyVal] = container
            }

            self.index = unkeyedContainer.index

            self.cachedNestedContainers = nestedContainers
            
            return nestedContainers
        }

        lazy var count: Int? = {
            do {
                let format = try self.readByte()
                switch format {
                case 0xa0...0xb7 :
                    return Int(format & 0x1F)
                case 0xb8:
                    return Int(try read(UInt8.self))
                case 0xb9:
                    return Int(try read(UInt16.self))
                case 0xba:
                    return Int(try read(UInt32.self))
                case 0xbb:
                    return Int(try read(UInt64.self))
                case 0xbf:
                    // FIXME: This is a very inefficient way of doing this. Really we should be modifying the
                    // nestedContainers code so that if we're working with a map that has a break at the end
                    // it creates the containers as it goes, rather than first calculating the count (which
                    // involves going through all the bytes) and then going back through the data and decoding
                    // each key-value pair in the map.
                    let nextIndex = self.data.startIndex.advanced(by: 1)
                    let remainingData = self.data.suffix(from: nextIndex)
                    return try? CBORDecoder(input: remainingData.map { $0 }).readPairsUntilBreak().keys.count
                default:
                    return nil
                }
            } catch {
                return nil
            }
        }()

        var data: Data
        var index: Data.Index
        var codingPath: [CodingKey]
        var userInfo: [CodingUserInfoKey: Any]

        init(data: Data, codingPath: [CodingKey], userInfo: [CodingUserInfoKey : Any]) {
            self.codingPath = codingPath
            self.userInfo = userInfo
            self.data = data
            self.index = self.data.startIndex
        }

        func checkCanDecodeValue(forKey key: Key) throws {
            guard self.contains(key) else {
                let context = DecodingError.Context(codingPath: self.codingPath, debugDescription: "key not found: \(key)")
                throw DecodingError.keyNotFound(key, context)
            }
        }
    }
}

extension _CBORDecoder.KeyedContainer: KeyedDecodingContainerProtocol {
    var allKeys: [Key] {
        return (try? self.getNestedContainers().keys.map { $0.key() }) ?? []
    }

    func contains(_ key: Key) -> Bool {
        return (try? self.getNestedContainers().keys.contains(AnyCodingKey(key))) ?? false
    }

    func decodeNil(forKey key: Key) throws -> Bool {
        try checkCanDecodeValue(forKey: key)

        guard let singleValueContainer = try self.getNestedContainers()[AnyCodingKey(key)] as? _CBORDecoder.SingleValueContainer else {
            let context = DecodingError.Context(codingPath: self.codingPath, debugDescription: "cannot decode nil for key: \(key)")
            throw DecodingError.typeMismatch(Any?.self, context)
        }

        return singleValueContainer.decodeNil()
    }

    func decode<T: Decodable>(_ type: T.Type, forKey key: Key) throws -> T {
        try checkCanDecodeValue(forKey: key)

        let container = try self.getNestedContainers()[AnyCodingKey(key)]!
        let decoder = CodableCBORDecoder()
        let value = try decoder.decode(T.self, from: container.data)

        return value
    }

    func nestedUnkeyedContainer(forKey key: Key) throws -> UnkeyedDecodingContainer {
        try checkCanDecodeValue(forKey: key)

        guard let unkeyedContainer = try self.getNestedContainers()[AnyCodingKey(key)] as? _CBORDecoder.UnkeyedContainer else {
            throw DecodingError.dataCorruptedError(forKey: key, in: self, debugDescription: "cannot decode nested container for key: \(key)")
        }

        return unkeyedContainer
    }

    func nestedContainer<NestedKey: CodingKey>(keyedBy type: NestedKey.Type, forKey key: Key) throws -> KeyedDecodingContainer<NestedKey> {
        try checkCanDecodeValue(forKey: key)

        guard let keyedContainer = try self.getNestedContainers()[AnyCodingKey(key)] as? _CBORDecoder.KeyedContainer<NestedKey> else {
            throw DecodingError.dataCorruptedError(forKey: key, in: self, debugDescription: "cannot decode nested container for key: \(key)")
        }

        return KeyedDecodingContainer(keyedContainer)
    }

    func superDecoder() throws -> Decoder {
        return _CBORDecoder(data: self.data)
    }

    func superDecoder(forKey key: Key) throws -> Decoder {
        let decoder = _CBORDecoder(data: self.data)
        decoder.codingPath = [key]

        return decoder
    }
}

extension _CBORDecoder.KeyedContainer: CBORDecodingContainer {}
