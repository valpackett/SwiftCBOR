import XCTest
import SwiftCBOR

final class ShortestIntegerEncodingCodableTests: XCTestCase {
    private struct Wrapper: Codable, Equatable {
        let value: UInt16
    }

    func testCodablePreservesFixedWidthUnsignedIntegersByDefault() throws {
        let encoder = CodableCBOREncoder()

        let data = try encoder.encode(Wrapper(value: 1))
        XCTAssertEqual([UInt8](data), [0xa1, 0x65, 0x76, 0x61, 0x6c, 0x75, 0x65, 0x19, 0x00, 0x01])
    }

    func testCodableCanUseShortestIntegerEncoding() throws {
        let encoder = CodableCBOREncoder()
        encoder.useShortestIntegerEncoding = true

        let data = try encoder.encode(Wrapper(value: 1))
        XCTAssertEqual([UInt8](data), [0xa1, 0x65, 0x76, 0x61, 0x6c, 0x75, 0x65, 0x01])
    }
}
