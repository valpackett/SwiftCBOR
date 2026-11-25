import Foundation

protocol AnyKeyedContainer {
    var storage: KeyedContainerStorage { get }
}

final class KeyedContainerStorage {
    var entries: [AnyCodingKey: CBOREncodingContainer] = [:]
}

extension _CBOREncoder {
    final class KeyedContainer<Key: CodingKey>: AnyKeyedContainer {
        var storage: KeyedContainerStorage

        var codingPath: [CodingKey]
        var userInfo: [CodingUserInfoKey: Any]

        let options: CodableCBOREncoder._Options

        init(storage: KeyedContainerStorage = KeyedContainerStorage(), codingPath: [CodingKey], userInfo: [CodingUserInfoKey : Any], options: CodableCBOREncoder._Options) {
            self.storage = storage
            self.codingPath = codingPath
            self.userInfo = userInfo
            self.options = options
        }
    }
}

extension _CBOREncoder.KeyedContainer: KeyedEncodingContainerProtocol {
    func encodeNil(forKey key: Key) throws {
        var container = self.nestedSingleValueContainer(forKey: key)
        try container.encodeNil()
    }

    func encode<T: Encodable>(_ value: T, forKey key: Key) throws {
        var container = self.nestedSingleValueContainer(forKey: key)
        try container.encode(value)
    }

    private func nestedCodingPath(forKey key: CodingKey) -> [CodingKey] {
        return self.codingPath + [key]
    }

    private func nestedSingleValueContainer(forKey key: Key) -> SingleValueEncodingContainer {
        let container = _CBOREncoder.SingleValueContainer(
            codingPath: self.nestedCodingPath(forKey: key),
            userInfo: self.userInfo,
            options: self.options
        )
        self.storage.entries[anyCodingKeyForKey(key)] = container
        return container
    }

    func nestedUnkeyedContainer(forKey key: Key) -> UnkeyedEncodingContainer {
        let container = _CBOREncoder.UnkeyedContainer(
            codingPath: self.nestedCodingPath(forKey: key),
            userInfo: self.userInfo,
            options: self.options
        )
        self.storage.entries[anyCodingKeyForKey(key)] = container
        return container
    }

    func nestedContainer<NestedKey: CodingKey>(keyedBy keyType: NestedKey.Type, forKey key: Key) -> KeyedEncodingContainer<NestedKey> {
        let container = _CBOREncoder.KeyedContainer<NestedKey>(
            codingPath: self.nestedCodingPath(forKey: key),
            userInfo: self.userInfo,
            options: self.options
        )
        self.storage.entries[anyCodingKeyForKey(key)] = container
        return KeyedEncodingContainer(container)
    }

    fileprivate func anyCodingKeyForKey(_ key: Key) -> AnyCodingKey {
        return AnyCodingKey(key, useStringKey: self.options.useStringKeys)
    }

    func superEncoder() -> Encoder {
        // Use a special "super" key for encoding class hierarchies
        let superKey = AnyCodingKey(stringValue: "super")
        let encoder = _CBOREncoder(options: self.options)
        encoder.codingPath = self.codingPath + [superKey]
        encoder.userInfo = self.userInfo
        self.storage.entries[superKey] = encoder
        return encoder
    }

    func superEncoder(forKey key: Key) -> Encoder {
        let encoder = _CBOREncoder(options: self.options)
        encoder.codingPath = self.nestedCodingPath(forKey: key)
        encoder.userInfo = self.userInfo
        self.storage.entries[anyCodingKeyForKey(key)] = encoder
        return encoder
    }
}

extension _CBOREncoder.KeyedContainer: CBOREncodingContainer {
    var data: Data {
        // TODO: Check that this works for all sizes of map
        var data: [UInt8] = []
        data = storage.entries.count.encode()
        data[0] = data[0] | 0b101_00000
        let entries = self.storage.entries.map { key, container -> (encodedKey: Data, container: CBOREncodingContainer) in
            let keyContainer = _CBOREncoder.SingleValueContainer(codingPath: self.codingPath, userInfo: self.userInfo, options: self.options)
            try! keyContainer.encode(key)
            return (keyContainer.data, container)
        }
        let orderedEntries = options.shouldSortMapKeys ? entries.sorted(by: {
            $0.encodedKey.lexicographicallyPrecedes($1.encodedKey)
        }) : entries
        for entry in orderedEntries {
            data.append(contentsOf: entry.encodedKey)
            data.append(contentsOf: entry.container.data)
        }

        return Data(data)
    }
}
