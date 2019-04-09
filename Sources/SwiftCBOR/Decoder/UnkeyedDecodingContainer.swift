import Foundation

extension _CBORDecoder {
    final class UnkeyedContainer {
        var codingPath: [CodingKey]

        var nestedCodingPath: [CodingKey] {
            return self.codingPath + [AnyCodingKey(intValue: self.count ?? 0)!]
        }

        var userInfo: [CodingUserInfoKey: Any]

        var data: Data
        var index: Data.Index

        lazy var count: Int? = {
            do {
                let format = try self.readByte()
                switch format {
                case 0x80...0x97 :
                    return Int(format & 0x1F)
                case 0x98:
                    return Int(try read(UInt8.self))
                case 0x99:
                    return Int(try read(UInt16.self))
                case 0x9a:
                    return Int(try read(UInt32.self))
                case 0x9b:
                    return Int(try read(UInt64.self))
                case 0x9f:
                    // TODO: Data items follow, terminated by break
                    return nil
                default:
                    return nil
                }
            } catch {
                return nil
            }
        }()

        var currentIndex: Int = 0

        lazy var nestedContainers: [CBORDecodingContainer] = {
            guard let count = self.count else {
                return []
            }

            var nestedContainers: [CBORDecodingContainer] = []

            do {
                for _ in 0..<count {
                    let container = try self.decodeContainer()
                    nestedContainers.append(container)
                }
            } catch {
                fatalError("\(error)") // FIXME
            }

            self.currentIndex = 0

            return nestedContainers
        }()
       
        init(data: Data, codingPath: [CodingKey], userInfo: [CodingUserInfoKey : Any]) {
            self.codingPath = codingPath
            self.userInfo = userInfo
            self.data = data
            self.index = self.data.startIndex
        }

        var isAtEnd: Bool {
            guard let count = self.count else {
                return true
            }

            return currentIndex >= count
        }

        func checkCanDecodeValue() throws {
            guard !self.isAtEnd else {
                throw DecodingError.dataCorruptedError(in: self, debugDescription: "Unexpected end of data")
            }
        }

    }
}

extension _CBORDecoder.UnkeyedContainer: UnkeyedDecodingContainer {
    func decodeNil() throws -> Bool {
        try checkCanDecodeValue()
        defer { self.currentIndex += 1 }

        let container = self.nestedContainers[self.currentIndex] as! _CBORDecoder.SingleValueContainer
        let value = container.decodeNil()

        return value
    }
    
    func decode<T: Decodable>(_ type: T.Type) throws -> T {
        try checkCanDecodeValue()
        defer { self.currentIndex += 1 }

        let container = self.nestedContainers[self.currentIndex]
        let decoder = CodableCBORDecoder()
        let value = try decoder.decode(T.self, from: container.data)

        return value
    }
    
    func nestedUnkeyedContainer() throws -> UnkeyedDecodingContainer {
        try checkCanDecodeValue()
        defer { self.currentIndex += 1 }

        let container = self.nestedContainers[self.currentIndex] as! _CBORDecoder.UnkeyedContainer

        return container
    }
    
    func nestedContainer<NestedKey: CodingKey>(keyedBy type: NestedKey.Type) throws -> KeyedDecodingContainer<NestedKey> {
        try checkCanDecodeValue()
        defer { self.currentIndex += 1 }

        let container = self.nestedContainers[self.currentIndex] as! _CBORDecoder.KeyedContainer<NestedKey>

        return KeyedDecodingContainer(container)
    }

    func superDecoder() throws -> Decoder {
        return _CBORDecoder(data: self.data)
    }
}

extension _CBORDecoder.UnkeyedContainer {
    func decodeContainer() throws -> CBORDecodingContainer {
        try checkCanDecodeValue()
        defer { self.currentIndex += 1 }

        let startIndex = self.index

        let length: Int
        let format = try self.readByte()

        switch format {
        // Integers
        // Small positive and negative integers
        case 0x00...0x17, 0x20...0x37:
            length = 0
        // UInt8 in following byte
        case 0x18, 0x38:
            length = 1
        // UInt16 in following bytes
        case 0x19, 0x39:
            length = 2
        // UInt32 in following bytes
        case 0x1a, 0x3a:
            length = 4
        // UInt64 in following bytes
        case 0x1b, 0x3b:
            length = 8
        // Byte strings
        case 0x40...0x5b:
            length = try CBORDecoder(input: [0]).readLength(format, base: 0x40)
        // Terminated by break
        case 0x5f:

            #warning("FIXME")
            throw DecodingError.dataCorruptedError(in: self, debugDescription: "Handling byte strings with break bytes is not supported yet")
        // UTF8 strings
        case 0x60...0x7b:
            length = try CBORDecoder(input: [0]).readLength(format, base: 0x60)
        // Terminated by break
        case 0x7f:
            #warning("FIXME")
            throw DecodingError.dataCorruptedError(in: self, debugDescription: "Handling UTF8 strings with break bytes is not supported yet")
        // Arrays
        case 0x80...0x9f:
            let container = _CBORDecoder.UnkeyedContainer(data: self.data.suffix(from: startIndex), codingPath: self.nestedCodingPath, userInfo: self.userInfo)
            _ = container.nestedContainers

            self.index = container.index
            return container

//            length = try CBORDecoder(input: [0]).readLength(format, base: 0x80)
        // Terminated by break
//        case 0x9f:
//            #warning("FIXME")
        // Maps
        case 0xa0...0xbb:
            let container = _CBORDecoder.KeyedContainer<AnyCodingKey>(data: self.data.suffix(from: startIndex), codingPath: self.nestedCodingPath, userInfo: self.userInfo)
            _ = container.nestedContainers // FIXME

            self.index = container.index
            return container

//            length = try CBORDecoder(input: [0]).readLength(format, base: 0xa0)
        // Terminated by break
//        case 0xbf:
//            #warning("FIXME")

        case 0xc0...0xdb:
//            let tag = try CBORDecoder(input: [0]).readVarUInt(format, base: 0xc0)
//            guard let item = try decodeItem() else { throw CBORError.unfinishedSequence }
//            return CBOR.tagged(CBOR.Tag(rawValue: tag), item)
            #warning("FIXME")
            throw DecodingError.dataCorruptedError(in: self, debugDescription: "Handling tags is not supported yet")
        case 0xe0...0xf3:
            length = 0
        case 0xf4, 0xf5, 0xf6, 0xf7, 0xf8:
            length = 0
        case 0xf9:
            length = 2
        case 0xfa:
            length = 4
        case 0xfb:
            length = 8
        case 0xff:
            length = 0
        default:
            throw DecodingError.dataCorruptedError(in: self, debugDescription: "Invalid format: \(format)")
        }

        let range: Range<Data.Index> = startIndex..<self.index.advanced(by: length)
        self.index = range.upperBound

        let container = _CBORDecoder.SingleValueContainer(data: self.data.subdata(in: range), codingPath: self.codingPath, userInfo: self.userInfo)

        return container
    }
}

extension _CBORDecoder.UnkeyedContainer: CBORDecodingContainer {}
