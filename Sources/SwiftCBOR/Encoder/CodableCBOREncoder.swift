import Foundation

public class CodableCBOREncoder {
    public var useStringKeys: Bool = false

    struct _Options {
        let useStringKeys: Bool

        init(useStringKeys: Bool = false) {
            self.useStringKeys = useStringKeys
        }
    }

    var options: _Options {
        return _Options(useStringKeys: self.useStringKeys)
    }

    public init() {}

    public func encode(_ value: Encodable) throws -> Data {
        let encoder = _CBOREncoder(options: self.options)
        if let dateVal = value as? Date {
            return Data(CBOR.encodeDate(dateVal))
        } else if let dataVal = value as? Data {
            return Data(CBOR.encodeData(dataVal))
        }
        try value.encode(to: encoder)
        return encoder.data
    }

    func setOptions(_ newOptions: _Options) {
        self.useStringKeys = newOptions.useStringKeys
    }
}

final class _CBOREncoder {
    var codingPath: [CodingKey] = []

    var userInfo: [CodingUserInfoKey : Any] = [:]

    fileprivate var container: CBOREncodingContainer? {
        willSet {
            precondition(self.container == nil)
        }
    }

    var data: Data {
        return container?.data ?? Data()
    }

    let options: CodableCBOREncoder._Options

    init(options: CodableCBOREncoder._Options = CodableCBOREncoder._Options()) {
        self.options = options
    }
}

extension _CBOREncoder: Encoder {
    fileprivate func assertCanCreateContainer() {
        precondition(self.container == nil)
    }

    func container<Key: CodingKey>(keyedBy type: Key.Type) -> KeyedEncodingContainer<Key> {
        assertCanCreateContainer()

        let container = KeyedContainer<Key>(codingPath: self.codingPath, userInfo: self.userInfo, options: self.options)
        self.container = container

        return KeyedEncodingContainer(container)
    }

    func unkeyedContainer() -> UnkeyedEncodingContainer {
        assertCanCreateContainer()

        let container = UnkeyedContainer(codingPath: self.codingPath, userInfo: self.userInfo, options: self.options)
        self.container = container

        return container
    }

    func singleValueContainer() -> SingleValueEncodingContainer {
        assertCanCreateContainer()

        let container = SingleValueContainer(codingPath: self.codingPath, userInfo: self.userInfo, options: self.options)
        self.container = container

        return container
    }
}

protocol CBOREncodingContainer: AnyObject {
    var data: Data { get }
}
