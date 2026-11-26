import XCTest

@testable import SwiftCBOR

final class CBORIntegerArrayEncodingTests: XCTestCase {
    func testSpecializedIntegerArrayEncodingMatchesGenericEncoding() {
        let signedValues: [Int] = [-1, 0, 1, 23, 24, 255, 256, 65_535, 65_536,
                                   4_294_967_295, Int(Int32.max) + 1]
        XCTAssertEqual(
            signedValues.encode(options: CBOROptions()),
            signedValues.toCBOR(options: CBOROptions()).encode(options: CBOROptions())
        )

        let unsignedValues: [UInt64] = [0, 23, 24, 255, 256, 65_535, 65_536,
                                        4_294_967_295, UInt64(Int32.max) + 1]
        XCTAssertEqual(
            unsignedValues.encode(options: CBOROptions()),
            CBOR.encodeArray(unsignedValues)
        )
    }

    func testSpecializedIntegerArrayWriterMatchesGenericEncoding() {
        let values: [Int] = [-1, 0, 1, 23, 24, 255, 256, 65_535, 65_536,
                             4_294_967_295, Int(Int32.max) + 1]
        var output: [UInt8] = []
        values.encode(into: &output)
        XCTAssertEqual(
            output,
            values.toCBOR(options: CBOROptions()).encode(options: CBOROptions())
        )
    }

    func testPublicEncodingUsesSpecializedPathWithPreferredIntegerWidths() {
        let uint16Values: [UInt16] = [1]
        let uint16Expected: [UInt8] = [0x81, 0x01]
        XCTAssertEqual(CBOR.encodeArray(uint16Values), uint16Expected)
        XCTAssertEqual(CBOR.encode(uint16Values), uint16Expected)
        XCTAssertEqual(uint16Values.encode(), uint16Expected)
        var uint16Output: [UInt8] = []
        uint16Values.encode(into: &uint16Output)
        XCTAssertEqual(uint16Output, uint16Expected)

        let uint32Values: [UInt32] = [1]
        let uint32Expected: [UInt8] = [0x81, 0x01]
        XCTAssertEqual(CBOR.encodeArray(uint32Values), uint32Expected)
        XCTAssertEqual(CBOR.encode(uint32Values), uint32Expected)
        XCTAssertEqual(uint32Values.encode(), uint32Expected)
        var uint32Output: [UInt8] = []
        uint32Values.encode(into: &uint32Output)
        XCTAssertEqual(uint32Output, uint32Expected)

        let uint64Values: [UInt64] = [1]
        let uint64Expected: [UInt8] = [0x81, 0x01]
        XCTAssertEqual(CBOR.encodeArray(uint64Values), uint64Expected)
        XCTAssertEqual(CBOR.encode(uint64Values), uint64Expected)
        XCTAssertEqual(uint64Values.encode(), uint64Expected)
        var uint64Output: [UInt8] = []
        uint64Values.encode(into: &uint64Output)
        XCTAssertEqual(uint64Output, uint64Expected)
    }

    func testPublicSignedIntegerArrayEncodingMatchesGenericEncoding() {
        let values: [Int] = [-1, 0, 1, 23, 24, 255, 256, 65_535, 65_536,
                             4_294_967_295, Int(Int32.max) + 1]
        var output: [UInt8] = []
        values.encode(into: &output)

        XCTAssertEqual(CBOR.encodeArray(values), output)
        XCTAssertEqual(CBOR.encode(values), output)
        XCTAssertEqual(values.encode(), output)
    }

    func testFixedWidthIntegerEncodingOptionAppliesToPublicPaths() {
        let options = CBOROptions(useShortestIntegerEncoding: false)
        let values: [UInt16] = [1]
        let expected: [UInt8] = [0x81, 0x19, 0x00, 0x01]
        var output: [UInt8] = []
        values.encode(into: &output, options: options)

        XCTAssertEqual(CBOR.encodeArray(values, options: options), expected)
        XCTAssertEqual(CBOR.encode(values, options: options), expected)
        XCTAssertEqual(values.encode(options: options), expected)
        XCTAssertEqual(output, expected)
        XCTAssertEqual(UInt16(1).encode(options: options), [0x19, 0x00, 0x01])
        XCTAssertEqual(UInt32(1).encode(options: options), [0x1a, 0x00, 0x00, 0x00, 0x01])
        XCTAssertEqual(UInt64(1).encode(options: options), [0x1b, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x01])
    }
}
