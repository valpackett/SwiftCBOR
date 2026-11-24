import XCTest
@testable import SwiftCBOR

final class CodableCollectionSizeTests: XCTestCase {
    private let counts = [0, 23, 24, 255, 256, 65_535, 65_536]

    func testArrayCountEncodingBoundaries() throws {
        for count in counts {
            let values = Array(repeating: 1, count: count)
            let encoded = try CodableCBOREncoder().encode(values)
            let header = expectedHeader(count: count, major: 0x80)
            XCTAssertEqual(Array(encoded.prefix(header.count)), header, "Array count \(count)")

            let decoded = try CodableCBORDecoder().decode([Int].self, from: encoded)
            XCTAssertEqual(decoded.count, count)
        }
    }

    func testMapCountEncodingBoundaries() throws {
        for count in counts {
            let values = Dictionary(uniqueKeysWithValues: (0..<count).map { (String($0), $0) })
            let encoded = try CodableCBOREncoder().encode(values)
            let header = expectedHeader(count: count, major: 0xa0)
            XCTAssertEqual(Array(encoded.prefix(header.count)), header, "Map count \(count)")

            let decoded = try CodableCBORDecoder().decode([String: Int].self, from: encoded)
            XCTAssertEqual(decoded.count, count)
        }
    }

    private func expectedHeader(count: Int, major: UInt8) -> [UInt8] {
        if count < 24 {
            return [major | UInt8(count)]
        } else if count <= Int(UInt8.max) {
            return [major | 24, UInt8(count)]
        } else if count <= Int(UInt16.max) {
            return [major | 25, UInt8(count >> 8), UInt8(count & 0xff)]
        } else {
            return [
                major | 26,
                UInt8((count >> 24) & 0xff),
                UInt8((count >> 16) & 0xff),
                UInt8((count >> 8) & 0xff),
                UInt8(count & 0xff)
            ]
        }
    }
}
