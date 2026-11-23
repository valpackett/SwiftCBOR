import XCTest
@testable import SwiftCBOR

class NegativeIntegerTests: XCTestCase {
    /// RFC 8949 Section 3.1: a negative integer is encoded as the unsigned integer n, and
    /// its value is -1 - n.
    func testEncodesNegativeIntegers() {
        XCTAssertEqual(CBOR.negativeInt(0).encode(), [0x20])
        XCTAssertEqual(CBOR.negativeInt(499).encode(), [0x39, 0x01, 0xf3])
        XCTAssertEqual(CBOR.negativeInt(3).encode(), [0x23])
    }

    /// The most negative integer CBOR can express is -2^64, which the decoder accepts and
    /// the encoder has to be able to encode again.
    func testEncodesTheMostNegativeInteger() throws {
        let mostNegative: [UInt8] = [0x3b, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff]
        let decoded = try XCTUnwrap(CBOR.decode(mostNegative))
        guard case let .negativeInt(n) = decoded else { return XCTFail("not a negative integer") }
        XCTAssertEqual(n, UInt64.max)
        XCTAssertEqual(decoded.encode(), mostNegative)
    }

    /// A negative integer that is decoded is encoded again as it was.
    func testRoundTripsNegativeIntegers() throws {
        for bytes in [[UInt8]([0x20]), [0x39, 0x01, 0xf3], [0x3b, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff]] {
            let decoded = try XCTUnwrap(CBOR.decode(bytes))
            XCTAssertEqual(decoded.encode(), bytes)
        }
    }
}
