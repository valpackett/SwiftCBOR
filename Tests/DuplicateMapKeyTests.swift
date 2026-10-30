import XCTest
@testable import SwiftCBOR

final class DuplicateMapKeyTests: XCTestCase {
    // Both encodings represent {"a": 1, "a": 2}.
    private let duplicateMaps: [[UInt8]] = [
        [0xa2, 0x61, 0x61, 0x01, 0x61, 0x61, 0x02],
        [0xbf, 0x61, 0x61, 0x01, 0x61, 0x61, 0x02, 0xff],
    ]

    func testDefaultKeepsLastValueForDuplicateKeys() throws {
        for bytes in duplicateMaps {
            XCTAssertEqual(try CBOR.decode(bytes), CBOR.map(["a": 2]))
            XCTAssertEqual(
                try CBOR.decode(bytes, options: CBOROptions(rejectDuplicateMapKeys: false)),
                CBOR.map(["a": 2])
            )
        }
    }

    func testRejectsDuplicateKeysInBothMapForms() {
        for bytes in duplicateMaps {
            assertDuplicateKey(bytes)
        }
    }

    func testRejectsEquivalentKeyEncodingsAndNullValues() {
        let inputs: [[UInt8]] = [
            [0xa2, 0x01, 0x00, 0x18, 0x01, 0x02], // 1 and non-minimally encoded 1
            [0xbf, 0x01, 0x00, 0x18, 0x01, 0x02, 0xff],
            [0xa2, 0x61, 0x61, 0x00, 0x7f, 0x61, 0x61, 0xff, 0x02], // "a" in two forms
            [0xa2, 0x01, 0xf6, 0x01, 0x02], // First value is CBOR null
            [0xbf, 0x01, 0xf6, 0x01, 0x02, 0xff],
        ]
        for bytes in inputs {
            assertDuplicateKey(bytes)
        }
    }

    func testRejectsNestedDuplicateKeys() {
        for bytes in duplicateMaps {
            assertDuplicateKey([0x81] + bytes) // Array
            assertDuplicateKey([0xa1, 0x00] + bytes) // Map value
            assertDuplicateKey([0xc2] + bytes) // Tagged value
            assertDuplicateKey([0xa1] + bytes + [0x00]) // Map key
        }
    }

    func testAcceptsUniqueKeysAndRepeatedKeysInSeparateMaps() throws {
        let inputs: [[UInt8]] = [
            [0xa0], [0xbf, 0xff], // Empty maps
            [0xa2, 0x61, 0x61, 0x01, 0x61, 0x62, 0x02],
            [0xbf, 0x61, 0x61, 0x01, 0x61, 0x62, 0x02, 0xff],
            [0xa2, 0x01, 0x00, 0x61, 0x31, 0x02], // Integer 1 and string "1"
            [0x82, 0xa1, 0x01, 0x00, 0xa1, 0x01, 0x02],
        ]
        for bytes in inputs {
            XCTAssertEqual(
                try CBOR.decode(bytes, options: CBOROptions(rejectDuplicateMapKeys: true)),
                try CBOR.decode(bytes)
            )
        }
    }

    private func assertDuplicateKey(_ bytes: [UInt8], file: StaticString = #filePath, line: UInt = #line) {
        XCTAssertThrowsError(
            try CBOR.decode(bytes, options: CBOROptions(rejectDuplicateMapKeys: true)),
            file: file, line: line
        ) { error in
            guard case CBORError.duplicateMapKey = error else {
                return XCTFail("Expected duplicateMapKey, got \(error)", file: file, line: line)
            }
        }
    }
}
