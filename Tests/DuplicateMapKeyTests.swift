import XCTest
@testable import SwiftCBOR

class DuplicateMapKeyTests: XCTestCase {
    /// {"a": 1, "a": 2}
    private let duplicateKeys: [UInt8] = [0xa2, 0x61, 0x61, 0x01, 0x61, 0x61, 0x02]

    /// A map with duplicate keys is well formed, but not valid. By default the decoder
    /// keeps the last value for the key, which is what RFC 8949 Section 5.6 calls losing
    /// some entries with duplicate keys.
    func testDuplicateKeysAreKeptByDefault() throws {
        let decoded = try XCTUnwrap(CBOR.decode(duplicateKeys))
        guard case let .map(map) = decoded else { return XCTFail() }
        XCTAssertEqual(map.count, 1)
        XCTAssertEqual(map["a"], CBOR.unsignedInt(2))
    }

    /// The decoder can reject a map with duplicate keys instead.
    func testDuplicateKeysCanBeRejected() {
        XCTAssertThrowsError(
            try CBOR.decode(duplicateKeys, options: CBOROptions(rejectDuplicateMapKeys: true))
        ) { error in
            XCTAssertEqual(error as? CBORError, CBORError.duplicateMapKey)
        }
    }

    /// A map with the same key twice in an indefinite length map is rejected as well.
    func testDuplicateKeysCanBeRejectedInAnIndefiniteLengthMap() {
        // {_ "a": 1, "a": 2}
        let indefinite: [UInt8] = [0xbf, 0x61, 0x61, 0x01, 0x61, 0x61, 0x02, 0xff]
        XCTAssertThrowsError(
            try CBOR.decode(indefinite, options: CBOROptions(rejectDuplicateMapKeys: true))
        ) { error in
            XCTAssertEqual(error as? CBORError, CBORError.duplicateMapKey)
        }
    }

    /// A map with distinct keys is not affected.
    func testDistinctKeysAreNotRejected() throws {
        let distinct: [UInt8] = [0xa2, 0x61, 0x61, 0x01, 0x61, 0x62, 0x02]
        XCTAssertNoThrow(try CBOR.decode(distinct, options: CBOROptions(rejectDuplicateMapKeys: true)))
    }
}
