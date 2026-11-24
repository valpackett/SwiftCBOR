import XCTest
@testable import SwiftCBOR

final class CBOREncodableWriterTests: XCTestCase {
    func testDirectConformerAppendsToTheSharedBuffer() {
        let value = DirectConformer()
        var output: [UInt8] = [0xff]

        value.encode(into: &output, options: CBOROptions())

        XCTAssertEqual(output, [0xff, 0x01])
        XCTAssertEqual(value.writerCallCount, 1)
    }

    func testGenericEncodeUsesTheDirectConformer() {
        let value = DirectConformer()

        XCTAssertEqual(CBOR.encode(value), [0x01])
        XCTAssertEqual(value.writerCallCount, 1)
    }

    func testLegacyConformerKeepsItsCustomEncoding() {
        let bytes: [UInt8] = [0x42, 0x01, 0x02]
        let value = RawBytesConformer(bytes: bytes)

        XCTAssertEqual(CBOR.encode(value), bytes)
    }

    func testToCBORConformerUsesTheCBORWriterPath() throws {
        let value = MetadataConformer(id: [1, 2], length: 2)
        let expected: CBOR = [
            "_id": .byteString([1, 2]),
            "_len": .unsignedInt(2)
        ]

        let encoded = CBOR.encode(value)
        let decoded = try XCTUnwrap(CBOR.decode(encoded))
        XCTAssertEqual(decoded, expected)
    }
}

private final class DirectConformer: CBOREncodable {
    var writerCallCount = 0

    func encode(options: CBOROptions) -> [UInt8] {
        [0x01]
    }

    func encode(into output: inout [UInt8], options: CBOROptions) {
        writerCallCount += 1
        output.append(0x01)
    }

    func toCBOR(options: CBOROptions) -> CBOR {
        .unsignedInt(1)
    }
}

private struct RawBytesConformer: CBOREncodable {
    let bytes: [UInt8]

    func encode(options: CBOROptions) -> [UInt8] {
        bytes
    }

    func toCBOR(options: CBOROptions) -> CBOR {
        .byteString(bytes)
    }
}

private struct MetadataConformer: CBOREncodable {
    let id: [UInt8]
    let length: Int

    func toCBOR(options: CBOROptions) -> CBOR {
        [
            "_id": .byteString(id),
            "_len": .unsignedInt(UInt64(length))
        ]
    }
}
