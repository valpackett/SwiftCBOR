import XCTest
import Foundation
@testable import SwiftCBOR

@available(macOS 12.3, iOS 15.4, watchOS 8.5, tvOS 15.4, *)
enum Direction: String, CodingKeyRepresentable, Codable {
    case north
    case south
}

/// A dictionary whose keys are not a plain String or an Int is decoded and encoded through
/// CodingKeyRepresentable, which the standard library supports since Swift 5.6.
class CodingKeyRepresentableTests: XCTestCase {
    @available(macOS 12.3, iOS 15.4, watchOS 8.5, tvOS 15.4, *)
    func testDecodesCodingKeyRepresentableKeys() throws {
        // {"north": 1, "south": 2}
        let cbor: [UInt8] = [0xa2, 0x65, 0x6e, 0x6f, 0x72, 0x74, 0x68, 0x01, 0x65, 0x73, 0x6f, 0x75, 0x74, 0x68, 0x02]
        let decoded = try CodableCBORDecoder().decode([Direction: Int].self, from: Data(cbor))
        XCTAssertEqual(decoded, [.north: 1, .south: 2])
    }

    @available(macOS 12.3, iOS 15.4, watchOS 8.5, tvOS 15.4, *)
    func testEncodesCodingKeyRepresentableKeys() throws {
        let encoded = try CodableCBOREncoder().encode([Direction.north: 1, .south: 2])
        let decoded = try CodableCBORDecoder().decode([Direction: Int].self, from: encoded)
        XCTAssertEqual(decoded, [.north: 1, .south: 2])
    }
}
