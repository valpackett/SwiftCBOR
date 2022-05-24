import XCTest
@testable import SwiftCBOR

class CBOREncodableTests: XCTestCase {
    func testToCBOR() {
        XCTAssertEqual(CBOR.unsignedInt(0), 0.toCBOR(options: CBOROptions()))
        XCTAssertEqual(CBOR.unsignedInt(1), 1.toCBOR(options: CBOROptions()))
        XCTAssertEqual(CBOR.unsignedInt(20), 20.toCBOR(options: CBOROptions()))

        XCTAssertEqual(CBOR.unsignedInt(UInt64(Int8.max)), Int8.max.toCBOR(options: CBOROptions()))
        XCTAssertEqual(127, Int8.max.toCBOR(options: CBOROptions()))
        XCTAssertEqual(CBOR.unsignedInt(UInt64(Int16.max)), Int16.max.toCBOR(options: CBOROptions()))
        XCTAssertEqual(32_767, Int16.max.toCBOR(options: CBOROptions()))
        XCTAssertEqual(CBOR.unsignedInt(UInt64(Int32.max)), Int32.max.toCBOR(options: CBOROptions()))
        XCTAssertEqual(2_147_483_647, Int32.max.toCBOR(options: CBOROptions()))
        XCTAssertEqual(CBOR.unsignedInt(UInt64(Int64.max)), Int64.max.toCBOR(options: CBOROptions()))
        XCTAssertEqual(9_223_372_036_854_775_807, Int64.max.toCBOR(options: CBOROptions()))

        XCTAssertEqual(CBOR.unsignedInt(UInt64(UInt8.max)), UInt8.max.toCBOR(options: CBOROptions()))
        XCTAssertEqual(255, UInt8.max.toCBOR(options: CBOROptions()))
        XCTAssertEqual(CBOR.unsignedInt(UInt64(UInt16.max)), UInt16.max.toCBOR(options: CBOROptions()))
        XCTAssertEqual(65_535, UInt16.max.toCBOR(options: CBOROptions()))
        XCTAssertEqual(CBOR.unsignedInt(UInt64(UInt32.max)), UInt32.max.toCBOR(options: CBOROptions()))
        XCTAssertEqual(4_294_967_295, UInt32.max.toCBOR(options: CBOROptions()))
        XCTAssertEqual(CBOR.unsignedInt(UInt64.max), UInt64.max.toCBOR(options: CBOROptions()))

        XCTAssertEqual(CBOR.negativeInt(~UInt64(bitPattern: Int64(Int8.min))), Int8.min.toCBOR(options: CBOROptions()))
        XCTAssertEqual(-128, Int8.min.toCBOR(options: CBOROptions()))
        XCTAssertEqual(CBOR.negativeInt(~UInt64(bitPattern: Int64(Int16.min))), Int16.min.toCBOR(options: CBOROptions()))
        XCTAssertEqual(-32_768, Int16.min.toCBOR(options: CBOROptions()))
        XCTAssertEqual(CBOR.negativeInt(~UInt64(bitPattern: Int64(Int32.min))), Int32.min.toCBOR(options: CBOROptions()))
        XCTAssertEqual(-2_147_483_648, Int32.min.toCBOR(options: CBOROptions()))
        XCTAssertEqual(CBOR.negativeInt(~UInt64(bitPattern: Int64(Int64.min))), Int64.min.toCBOR(options: CBOROptions()))
        XCTAssertEqual(-9_223_372_036_854_775_808, Int64.min.toCBOR(options: CBOROptions()))

        XCTAssertEqual(CBOR.double(Double.greatestFiniteMagnitude), Double.greatestFiniteMagnitude.toCBOR(options: CBOROptions()))
        XCTAssertEqual(CBOR.double(Double.leastNonzeroMagnitude), Double.leastNonzeroMagnitude.toCBOR(options: CBOROptions()))
        XCTAssertEqual(CBOR.double(Double.pi), Double.pi.toCBOR(options: CBOROptions()))
        XCTAssertEqual(CBOR.double(0.123456789), 0.123456789.toCBOR(options: CBOROptions()))

        XCTAssertEqual(CBOR.float(Float.greatestFiniteMagnitude), Float.greatestFiniteMagnitude.toCBOR(options: CBOROptions()))
        XCTAssertEqual(CBOR.float(Float.leastNonzeroMagnitude), Float.leastNonzeroMagnitude.toCBOR(options: CBOROptions()))
        XCTAssertEqual(CBOR.float(Float.pi), Float.pi.toCBOR(options: CBOROptions()))
        XCTAssertEqual(CBOR.float(0.123456789), Float(0.123456789).toCBOR(options: CBOROptions()))

        XCTAssertEqual(CBOR.boolean(true), true.toCBOR(options: CBOROptions()))
        XCTAssertEqual(true, true.toCBOR(options: CBOROptions()))
        XCTAssertEqual(CBOR.boolean(false), false.toCBOR(options: CBOROptions()))
        XCTAssertEqual(false, false.toCBOR(options: CBOROptions()))

        XCTAssertEqual(CBOR.utf8String("test"), "test".toCBOR(options: CBOROptions()))
        XCTAssertEqual("test", "test".toCBOR(options: CBOROptions()))

        XCTAssertEqual(CBOR.null, Optional<String>.none.toCBOR(options: CBOROptions()))
        XCTAssertEqual(nil, Optional<String>.none.toCBOR(options: CBOROptions()))

        XCTAssertEqual(CBOR.byteString([1, 2, 3]), Data([1, 2, 3]).toCBOR(options: CBOROptions()))

        XCTAssertEqual(CBOR.array([CBOR.unsignedInt(1), CBOR.unsignedInt(2)]), [1, 2].toCBOR(options: CBOROptions()))

        XCTAssertEqual(
            CBOR.map([CBOR.utf8String("a"): CBOR.unsignedInt(1), CBOR.utf8String("b"): CBOR.unsignedInt(2)]),
            ["a": 1, "b": 2].toCBOR(options: CBOROptions())
        )
    }
}
