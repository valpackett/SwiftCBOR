import XCTest
@testable import SwiftCBOR

class CBORMapTests: XCTestCase {
    /// A map that is decoded keeps the order the keys arrived in.
    func testDecodingPreservesKeyOrder() throws {
        // {"z": 1, "a": 2, "m": 3}
        let input: [UInt8] = [0xa3, 0x61, 0x7a, 0x01, 0x61, 0x61, 0x02, 0x61, 0x6d, 0x03]
        let decoded = try XCTUnwrap(CBOR.decode(input))
        guard case let .map(map) = decoded else { return XCTFail() }
        XCTAssertEqual(map.keys, [CBOR.utf8String("z"), CBOR.utf8String("a"), CBOR.utf8String("m")])
    }

    /// A map that is decoded and encoded again keeps its order when the keys are not sorted.
    func testEncodingPreservesKeyOrder() throws {
        let input: [UInt8] = [0xa3, 0x61, 0x7a, 0x01, 0x61, 0x61, 0x02, 0x61, 0x6d, 0x03]
        let decoded = try XCTUnwrap(CBOR.decode(input))
        let encoded = decoded.encode(options: CBOROptions(shouldSortMapKeys: false))
        XCTAssertEqual(encoded, input)
    }

    /// The keys are sorted by their encoded bytes, as RFC 8949 Section 4.2.1 requires.
    func testEncodingSortsKeysByTheirEncodedBytes() throws {
        let input: [UInt8] = [0xa3, 0x61, 0x7a, 0x01, 0x61, 0x61, 0x02, 0x61, 0x6d, 0x03]
        let decoded = try XCTUnwrap(CBOR.decode(input))
        // "a" (0x6161) sorts before "m" (0x616d), which sorts before "z" (0x617a).
        let encoded = decoded.encode(options: CBOROptions(shouldSortMapKeys: true))
        XCTAssertEqual(encoded, [0xa3, 0x61, 0x61, 0x02, 0x61, 0x6d, 0x03, 0x61, 0x7a, 0x01])
    }

    /// A map is an unordered collection in the CBOR data model, so the order of its keys
    /// does not affect its equality.
    func testEqualityIgnoresKeyOrder() {
        let one = CBORMap([("a", CBOR.unsignedInt(1)), ("b", CBOR.unsignedInt(2))])
        let other = CBORMap([("b", CBOR.unsignedInt(2)), ("a", CBOR.unsignedInt(1))])
        XCTAssertEqual(one, other)
        XCTAssertEqual(one.hashValue, other.hashValue)
        XCTAssertEqual(CBOR.map(one), CBOR.map(other))
    }

    /// Setting the value for a key that is already there replaces the value and leaves the
    /// key where it is.
    func testSettingAValueKeepsTheKeyInPlace() {
        var map = CBORMap([("a", CBOR.unsignedInt(1)), ("b", CBOR.unsignedInt(2))])
        map["a"] = CBOR.unsignedInt(3)
        XCTAssertEqual(map.keys, [CBOR.utf8String("a"), CBOR.utf8String("b")])
        XCTAssertEqual(map["a"], CBOR.unsignedInt(3))
    }

    /// Removing a key removes it from the order too.
    func testRemovingAKeyRemovesItFromTheOrder() {
        var map = CBORMap([("a", CBOR.unsignedInt(1)), ("b", CBOR.unsignedInt(2))])
        map["a"] = nil
        XCTAssertEqual(map.keys, [CBOR.utf8String("b")])
        XCTAssertEqual(map.count, 1)
    }

    /// The encoder keeps the keys of a Codable object in the order they were encoded in.
    func testCodableEncoderKeepsKeyOrder() throws {
        struct Ordered: Codable, Equatable {
            let zebra: Int
            let apple: Int
            let mango: Int
        }
        let encoded = try CodableCBOREncoder().encode(Ordered(zebra: 1, apple: 2, mango: 3))
        // The map header, then the keys in the order they were declared in.
        XCTAssertEqual(Array(encoded.prefix(11)), [0xa3, 0x65, 0x7a, 0x65, 0x62, 0x72, 0x61, 0x01, 0x65, 0x61, 0x70])
    }
}
