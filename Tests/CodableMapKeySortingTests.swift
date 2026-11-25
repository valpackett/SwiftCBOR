import XCTest
@testable import SwiftCBOR

final class CodableMapKeySortingTests: XCTestCase {
    func testStringKeysUseEncodedByteOrder() throws {
        let encoded = try CodableCBOREncoder().encode(["aa": 1, "z": 2])

        XCTAssertEqual(encoded, Data([
            0xa2,
            0x61, 0x7a, 0x02,
            0x62, 0x61, 0x61, 0x01,
        ]))
    }

    func testIntegerKeysUseEncodedByteOrder() throws {
        let encoded = try CodableCBOREncoder().encode([24: 1, 3: 2, 1_000: 3])

        XCTAssertEqual(encoded, Data([
            0xa3,
            0x03, 0x02,
            0x18, 0x18, 0x01,
            0x19, 0x03, 0xe8, 0x03,
        ]))
    }

    func testNestedMapKeysAreSorted() throws {
        let encoded = try CodableCBOREncoder().encode(["outer": ["aa": 1, "z": 2]])

        XCTAssertEqual(encoded, Data([
            0xa1,
            0x65, 0x6f, 0x75, 0x74, 0x65, 0x72,
            0xa2,
            0x61, 0x7a, 0x02,
            0x62, 0x61, 0x61, 0x01,
        ]))
    }

    func testMixedKeysUseEncodedByteOrder() throws {
        struct MixedKeyMap: Encodable {
            func encode(to encoder: Encoder) throws {
                var container = encoder.container(keyedBy: AnyCodingKey.self)
                try container.encode(1, forKey: AnyCodingKey(stringValue: "aa"))
                try container.encode(2, forKey: AnyCodingKey(stringValue: "z"))
                try container.encode(3, forKey: AnyCodingKey(intValue: 24))
                try container.encode(4, forKey: AnyCodingKey(intValue: 3))
            }
        }

        let encoded = try CodableCBOREncoder().encode(MixedKeyMap())

        XCTAssertEqual(encoded, Data([
            0xa4,
            0x03, 0x04,
            0x18, 0x18, 0x03,
            0x61, 0x7a, 0x02,
            0x62, 0x61, 0x61, 0x01,
        ]))
    }

    func testMapKeySortingOptionIsPropagated() {
        let encoder = CodableCBOREncoder()
        encoder.shouldSortMapKeys = false

        XCTAssertFalse(encoder.options.shouldSortMapKeys)
        XCTAssertFalse(encoder.options.toCBOROptions().shouldSortMapKeys)
        XCTAssertFalse(CBOROptions(shouldSortMapKeys: false).toCodableEncoderOptions().shouldSortMapKeys)
    }
}
