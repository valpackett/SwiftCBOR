import XCTest
@testable import SwiftCBOR

class CBORStreamEncoderTests: XCTestCase {
    static var allTests = [
        ("testEncodeInts", testEncodeInts),
        ("testEncodeByteStrings", testEncodeByteStrings),
        ("testEncodeData", testEncodeData),
        ("testEncodeUtf8Strings", testEncodeUtf8Strings),
        ("testEncodeArrays", testEncodeArrays),
        ("testEncodeMaps", testEncodeMaps),
        ("testEncodeTagged", testEncodeTagged),
        ("testEncodeSimple", testEncodeSimple),
        ("testEncodeFloats", testEncodeFloats),
        ("testEncodeIndefiniteArrays", testEncodeIndefiniteArrays),
        ("testEncodeIndefiniteMaps", testEncodeIndefiniteMaps),
        ("testEncodeIndefiniteStrings", testEncodeIndefiniteStrings),
        ("testEncodeIndefiniteByteStrings", testEncodeIndefiniteByteStrings),
        ("testReadmeExamples", testReadmeExamples),
    ]

    func stream(_ type: CBORStreamEncoder.StreamableItemType, block: (CBORStreamEncoder) throws -> Void) throws -> [UInt8] {
        return try encode { encoder in
            try encoder.encodeIndefiniteStart(for: type)
            defer { try? encoder.encodeIndefiniteEnd() }
            try block(encoder)
        }
    }

    func encode(block: (CBORStreamEncoder) throws -> Void) rethrows -> [UInt8] {
        let stream = CBORDataStream()
        let encoder = CBORStreamEncoder(stream: stream)
        try block(encoder)
        return Array(stream.data)
    }

    func testEncodeInts() {
        for i in 0..<24 {
            XCTAssertEqual(try encode { try $0.encodeInt(i) }, [UInt8(i)])
            XCTAssertEqual(try encode { try $0.encodeInt(-i) }.count, 1)
        }
        XCTAssertEqual(try encode { try $0.encodeInt(-1) }, [0x20])
        XCTAssertEqual(try encode { try $0.encodeInt(-10) }, [0x29])
        XCTAssertEqual(try encode { try $0.encodeInt(-24) }, [0x37])
        XCTAssertEqual(try encode { try $0.encodeInt(-25) }, [0x38, 24])
        XCTAssertEqual(try encode { try $0.encodeInt(1000000) }, [0x1a, 0x00, 0x0f, 0x42, 0x40])
        XCTAssertEqual(try encode { try $0.encodeInt(4294967295) }, [0x1a, 0xff, 0xff, 0xff, 0xff]) //UInt32.max
        XCTAssertEqual(try encode { try $0.encodeInt(1000000000000) }, [0x1b, 0x00, 0x00, 0x00, 0xe8, 0xd4, 0xa5, 0x10, 0x00])
        XCTAssertEqual(try encode { try $0.encodeInt(-1_000_000) }, [0x3a, 0x00, 0x0f, 0x42, 0x3f])
        XCTAssertEqual(try encode { try $0.encodeInt(-1_000_000_000_000) }, [0x3b, 0x00, 0x00, 0x00, 0xe8, 0xd4, 0xa5, 0x0f, 0xff])
    }

    func testEncodeByteStrings() {
        XCTAssertEqual(try encode { try $0.encodeByteString(Data()) }, [0x40])
        XCTAssertEqual(try encode { try $0.encodeByteString(Data([0xf0])) }, [0x41, 0xf0])
        XCTAssertEqual(try encode { try $0.encodeByteString(Data([0x01, 0x02, 0x03, 0x04])) }, [0x44, 0x01, 0x02, 0x03, 0x04])

        let bytes23 = Data([0xff, 0x00, 0xff, 0x00, 0xff, 0x00, 0xff, 0x00, 0xff, 0x00, 0xff, 0x00, 0xff, 0x00, 0xff, 0x00, 0xff, 0x00, 0xff, 0x00, 0xff, 0x00, 0xaa])
        XCTAssertEqual(try encode { try $0.encodeByteString(bytes23) }, [0x57] + bytes23)

        let bytes24 = bytes23 + [0xaa]
        XCTAssertEqual(try encode { try $0.encodeByteString(bytes24) }, [0x58, 24] + bytes24)
    }

    func testEncodeData() {
        XCTAssertEqual(try encode { try $0.encodeByteString(Data()) }, [0x40])
        XCTAssertEqual(try encode { try $0.encodeByteString(Data([0xf0])) }, [0x41, 0xf0])
        XCTAssertEqual(try encode { try $0.encodeByteString(Data([0x01, 0x02, 0x03, 0x04])) }, [0x44, 0x01, 0x02, 0x03, 0x04])

        let bytes23 = Data([0xff, 0x00, 0xff, 0x00, 0xff, 0x00, 0xff, 0x00, 0xff, 0x00, 0xff, 0x00, 0xff, 0x00, 0xff, 0x00, 0xff, 0x00, 0xff, 0x00, 0xff, 0x00, 0xaa])
        XCTAssertEqual(try encode { try $0.encodeByteString(bytes23) }, [0x57] + bytes23)

        let bytes24 = Data(bytes23 + [0xaa])
        XCTAssertEqual(try encode { try $0.encodeByteString(bytes24) }, [0x58, 24] + bytes24)
    }

    func testEncodeUtf8Strings() {
        XCTAssertEqual(try encode { try $0.encodeString("") }, [0x60])
        XCTAssertEqual(try encode { try $0.encodeString("a") }, [0x61, 0x61])
        XCTAssertEqual(try encode { try $0.encodeString("B") }, [0x61, 0x42])
        XCTAssertEqual(try encode { try $0.encodeString("ABC") }, [0x63, 0x41, 0x42, 0x43])
        XCTAssertEqual(try encode { try $0.encodeString("IETF") }, [0x64, 0x49, 0x45, 0x54, 0x46])
        XCTAssertEqual(try encode { try $0.encodeString("今日は") }, [0x69, 0xE4, 0xBB, 0x8A, 0xE6, 0x97, 0xA5, 0xE3, 0x81, 0xAF])
        XCTAssertEqual(try encode { try $0.encodeString("♨️français;日本語！Longer text\n with break?") },
                       [0x78, 0x34, 0xe2, 0x99, 0xa8, 0xef, 0xb8, 0x8f, 0x66, 0x72, 0x61, 0x6e, 0xc3, 0xa7, 0x61, 0x69, 0x73, 0x3b, 0xe6, 0x97, 0xa5, 0xe6, 0x9c, 0xac, 0xe8, 0xaa, 0x9e, 0xef, 0xbc, 0x81, 0x4c, 0x6f, 0x6e, 0x67, 0x65, 0x72, 0x20, 0x74, 0x65, 0x78, 0x74, 0x0a, 0x20, 0x77, 0x69, 0x74, 0x68, 0x20, 0x62, 0x72, 0x65, 0x61, 0x6b, 0x3f])
        XCTAssertEqual(try encode { try $0.encodeString("\"\\") }, [0x62, 0x22, 0x5c])
        XCTAssertEqual(try encode { try $0.encodeString("\u{6C34}") }, [0x63, 0xe6, 0xb0, 0xb4])
        XCTAssertEqual(try encode { try $0.encodeString("水") }, [0x63, 0xe6, 0xb0, 0xb4])
        XCTAssertEqual(try encode { try $0.encodeString("\u{00fc}") }, [0x62, 0xc3, 0xbc])
        XCTAssertEqual(try encode { try $0.encodeString("abc\n123") }, [0x67, 0x61, 0x62, 0x63, 0x0a, 0x31, 0x32, 0x33])
    }

    func testEncodeArrays() {
        XCTAssertEqual(try encode { try $0.encodeArray([]) }, [0x80])
        XCTAssertEqual(try encode { try $0.encodeArray([1, 2, 3]) }, [0x83, 0x01, 0x02, 0x03])
        XCTAssertEqual(try encode { try $0.encodeArray([[1], [2, 3], [4, 5]]) }, [0x83, 0x81, 0x01, 0x82, 0x02, 0x03, 0x82, 0x04, 0x05])
        XCTAssertEqual(try encode { try $0.encodeArray((1...25).map { CBOR($0) }) },
                       [0x98, 0x19, 0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08, 0x09, 0x0a, 0x0b, 0x0c, 0x0d, 0x0e, 0x0f, 0x10, 0x11, 0x12, 0x13, 0x14, 0x15, 0x16, 0x17, 0x18, 0x18, 0x18, 0x19])
    }

    func testEncodeMaps() throws {
        XCTAssertEqual(try encode { try $0.encodeMap([:]) }, [0xa0])

        let map = try encode { try $0.encodeMap([1: 2, 3: 4]) }
        XCTAssertTrue(map == [0xa2, 0x01, 0x02, 0x03, 0x04] || map == [0xa2, 0x03, 0x04, 0x01, 0x02])

        let nested = try encode { try $0.encodeMap(["a": [1], "b": [2, 3]]) }
        XCTAssertTrue(nested == [0xa2, 0x61, 0x61, 0x81, 0x01, 0x61, 0x62, 0x82, 0x02, 0x03] || nested == [0xa2, 0x61, 0x62, 0x82, 0x02, 0x03, 0x61, 0x61, 0x81, 0x01])
    }

    func testEncodeTagged() {
        let bignum = Data([0x01, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00]) // 2**64
        let bignumCBOR = CBOR.byteString(bignum)
        XCTAssertEqual(try encode { try $0.encodeTagged(tag: .positiveBignum, value: bignumCBOR) }, [0xc2, 0x49] + bignum)
        XCTAssertEqual(try encode { try $0.encodeTagged(tag: .init(rawValue: UInt64.max), value: bignumCBOR) }, [0xdb, 255, 255, 255, 255, 255, 255, 255, 255, 0x49] + bignum)
    }

    func testEncodeSimple() {
        XCTAssertEqual(try encode { try $0.encode(.boolean(false)) }, [0xf4])
        XCTAssertEqual(try encode { try $0.encode(.boolean(true)) }, [0xf5])
        XCTAssertEqual(try encode { try $0.encode(.null) }, [0xf6])
        XCTAssertEqual(try encode { try $0.encode(.undefined) }, [0xf7])
        XCTAssertEqual(try encode { try $0.encode(.simple(16)) }, [0xf0])
        XCTAssertEqual(try encode { try $0.encode(.simple(24)) }, [0xf8, 0x18])
        XCTAssertEqual(try encode { try $0.encode(.simple(255)) }, [0xf8, 0xff])
    }

    func testEncodeFloats() {
        // The following tests are modifications of examples of Float16 in the RFC
        XCTAssertEqual(try encode { try $0.encodeFloat(0.0) }, [0xfa,0x00, 0x00, 0x00, 0x00])
        XCTAssertEqual(try encode { try $0.encodeFloat(-0.0) }, [0xfa, 0x80, 0x00, 0x00, 0x00])
        XCTAssertEqual(try encode { try $0.encodeFloat(1.0) }, [0xfa, 0x3f, 0x80, 0x00, 0x00])
        XCTAssertEqual(try encode { try $0.encodeFloat(1.5) }, [0xfa,0x3f,0xc0, 0x00,0x00])
        XCTAssertEqual(try encode { try $0.encodeFloat(65504.0) }, [0xfa, 0x47, 0x7f, 0xe0, 0x00])

        // The following are seen as Float32s in the RFC
        XCTAssertEqual(try encode { try $0.encodeFloat(100000.0) }, [0xfa,0x47,0xc3,0x50,0x00])
        XCTAssertEqual(try encode { try $0.encodeFloat(3.4028234663852886e+38) }, [0xfa, 0x7f, 0x7f, 0xff, 0xff])

        // The following are seen as Doubles in the RFC
        XCTAssertEqual(try encode { try $0.encodeDouble(1.1) }, [0xfb,0x3f,0xf1,0x99,0x99,0x99,0x99,0x99,0x9a])
        XCTAssertEqual(try encode { try $0.encodeDouble(-4.1) }, [0xfb, 0xc0, 0x10, 0x66, 0x66, 0x66, 0x66, 0x66, 0x66])
        XCTAssertEqual(try encode { try $0.encodeDouble(1.0e+300) }, [0xfb, 0x7e, 0x37, 0xe4, 0x3c, 0x88, 0x00, 0x75, 0x9c])
        XCTAssertEqual(try encode { try $0.encodeDouble(5.960464477539063e-8) }, [0xfb, 0x3e, 0x70, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00])

        // Special values
        XCTAssertEqual(try encode { try $0.encodeFloat(.infinity) }, [0xfa, 0x7f, 0x80, 0x00, 0x00])
        XCTAssertEqual(try encode { try $0.encodeFloat(-.infinity) }, [0xfa, 0xff, 0x80, 0x00, 0x00])
        XCTAssertEqual(try encode { try $0.encodeDouble(.infinity) }, [0xfb, 0x7f, 0xf0, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00])
        XCTAssertEqual(try encode { try $0.encodeDouble(-.infinity) }, [0xfb, 0xff, 0xf0, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00])
        XCTAssertEqual(try encode { try $0.encodeFloat(.nan) }, [0xfa,0x7f, 0xc0, 0x00, 0x00])
        XCTAssertEqual(try encode { try $0.encodeDouble(.nan) }, [0xfb, 0x7f, 0xf8, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00])

        // Swift's floating point literals are read as Doubles unless specifically specified. e.g.
        XCTAssertEqual(try encode { try $0.encode(0.0) }, [0xfb,0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00])
    }

    func testEncodeIndefiniteArrays() throws {
        let encoded = try stream(.array) {
            try $0.encodeArrayChunk([1, 2])
            try $0.encodeInt(3)
            try $0.encodeIndefiniteStart(for: .array)
            try $0.encodeArrayChunk([1, 2, 3])
            try $0.encodeIndefiniteEnd()
        }
        XCTAssertEqual(encoded, [0x9f, 0x01, 0x02, 0x03, 0x9f, 0x01, 0x02, 0x03, 0xff, 0xff])
    }

    func testEncodeIndefiniteMaps() throws {
        let encoded = try stream(.map) {
            try $0.encodeMapChunk(["a": 1])
            try $0.encodeMapChunk(["B": 2])
        }
        XCTAssertEqual(encoded, [0xbf, 0x61, 0x61, 0x01, 0x61, 0x42, 0x02, 0xff])
    }

    func testEncodeIndefiniteStrings() throws {
        let encoded = try stream(.string) {
            try $0.encodeString("a")
            try $0.encodeString("B")
        }
        XCTAssertEqual(encoded, [0x7f, 0x61, 0x61, 0x61, 0x42, 0xff])
    }

    func testEncodeIndefiniteByteStrings() throws {
        let encoded = try stream(.byteString) {
            try $0.encodeByteString(Data([0xf0]))
            try $0.encodeByteString(Data([0xff]))
        }
        XCTAssertEqual(encoded, [0x5f, 0x41, 0xf0, 0x41, 0xff, 0xff])
    }

    func testReadmeExamples() throws {
        XCTAssertEqual(try encode { try $0.encode(100) }, [0x18, 0x64])
        XCTAssertEqual(try encode { try $0.encode("hello") }, [0x65, 0x68, 0x65, 0x6c, 0x6c, 0x6f])
        XCTAssertEqual(try encode { try $0.encodeArray(["a", "b", "c"]) }, [0x83, 0x61, 0x61, 0x61, 0x62, 0x61, 0x63])

        struct MyStruct {
            var x: Int
            var y: String

            public func encode() -> CBOR {
                return [
                    "x": CBOR(self.x),
                    "y": .utf8String(self.y)
                ]
            }
        }

        let encoded = try encode { try $0.encode(MyStruct(x: 42, y: "words").encode()) }
        XCTAssert(encoded == [0xa2, 0x61, 0x79, 0x65, 0x77, 0x6f, 0x72, 0x64, 0x73, 0x61, 0x78, 0x18, 0x2a] || encoded == [0xa2, 0x61, 0x78, 0x18, 0x2a, 0x61, 0x79, 0x65, 0x77, 0x6f, 0x72, 0x64, 0x73])
    }

}
