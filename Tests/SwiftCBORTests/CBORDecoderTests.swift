import XCTest
@testable import SwiftCBOR

class CBORDecoderTests: XCTestCase {
    static var allTests = [
        ("testDecodeNumbers", testDecodeNumbers),
        ("testDecodeByteStrings", testDecodeByteStrings),
        ("testDecodeUtf8Strings", testDecodeUtf8Strings),
        ("testDecodeArrays", testDecodeArrays),
        ("testDecodeMaps", testDecodeMaps),
        ("testDecodeTagged", testDecodeTagged),
        ("testDecodeSimple", testDecodeSimple),
        ("testDecodeFloats", testDecodeFloats),
        ("testDecodePerformance", testDecodePerformance),
    ]

    func testDecodeNumbers() {
        for i in (0..<24) {
            XCTAssertEqual(try! CBORDecoder(input: [UInt8(i)]).decodeItem(), CBOR.unsignedInt(UInt64(i)))
        }
        XCTAssertEqual(try! CBORDecoder(input: [0x18, 0xff]).decodeItem(), 255)
        XCTAssertEqual(try! CBORDecoder(input: [0x19, 0x03, 0xe8]).decodeItem(), 1000) // Network byte order!
        XCTAssertEqual(try! CBORDecoder(input: [0x19, 0xff, 0xff]).decodeItem(), 65535)
        do { _ = try CBORDecoder(input: [0x19, 0xff]).decodeItem(); XCTAssertTrue(false) } catch { XCTAssertTrue(true) }
        XCTAssertEqual(try! CBORDecoder(input: [0x1a, 0x00, 0x0f, 0x42, 0x40]).decodeItem(), 1000000)
        XCTAssertEqual(try! CBORDecoder(input: [0x1a, 0xff, 0xff, 0xff, 0xff]).decodeItem(), 4294967295)
        do { _ = try CBORDecoder(input: [0x1a]).decodeItem(); XCTAssertTrue(false) } catch { XCTAssertTrue(true) }
        XCTAssertEqual(try! CBORDecoder(input: [0x1b, 0x00, 0x00, 0x00, 0xe8, 0xd4, 0xa5, 0x10, 0x00]).decodeItem(), 1000000000000)
        XCTAssertEqual(try! CBORDecoder(input: [0x1b, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff]).decodeItem(), CBOR.unsignedInt(18446744073709551615))
        do { _ = try CBORDecoder(input: [0x1b, 0x00, 0x00]).decodeItem(); XCTAssertTrue(false) } catch { XCTAssertTrue(true) }

        XCTAssertEqual(try! CBORDecoder(input: [0x20]).decodeItem(), -1)
        XCTAssertEqual(try! CBORDecoder(input: [0x21]).decodeItem(), CBOR.negativeInt(1))
        XCTAssertEqual(try! CBORDecoder(input: [0x37]).decodeItem(), -24)
        XCTAssertEqual(try! CBORDecoder(input: [0x38, 0xff]).decodeItem(), -256)
        XCTAssertEqual(try! CBORDecoder(input: [0x39, 0x03, 0xe7]).decodeItem(), -1000)
        XCTAssertEqual(try! CBORDecoder(input: [0x3a, 0x00, 0x0f, 0x42, 0x3f]).decodeItem(), CBOR.negativeInt(999999))
        XCTAssertEqual(try! CBORDecoder(input: [0x3b, 0x00, 0x00, 0x00, 0xe8, 0xd4, 0xa5, 0x0f, 0xff]).decodeItem(), CBOR.negativeInt(999999999999))
    }

    func testDecodeByteStrings() {
        XCTAssertEqual(try! CBORDecoder(input: [0x40]).decodeItem(), CBOR.byteString([]))
        XCTAssertEqual(try! CBORDecoder(input: [0x41, 0xf0]).decodeItem(), CBOR.byteString([0xf0]))
        XCTAssertEqual(try! CBORDecoder(input: [0x57, 0xff, 0x00, 0xff, 0x00, 0xff, 0x00, 0xff, 0x00, 0xff, 0x00, 0xff, 0x00, 0xff, 0x00, 0xff, 0x00, 0xff, 0x00, 0xff, 0x00, 0xff, 0x00, 0xaa]).decodeItem(), CBOR.byteString([0xff, 0x00, 0xff, 0x00, 0xff, 0x00, 0xff, 0x00, 0xff, 0x00, 0xff, 0x00, 0xff, 0x00, 0xff, 0x00, 0xff, 0x00, 0xff, 0x00, 0xff, 0x00, 0xaa]))
        XCTAssertEqual(try! CBORDecoder(input: [0x58, 0]).decodeItem(), CBOR.byteString([]))
        XCTAssertEqual(try! CBORDecoder(input: [0x58, 1, 0xf0]).decodeItem(), CBOR.byteString([0xf0]))
        XCTAssertEqual(try! CBORDecoder(input: [0x59, 0x00, 3, 0xc0, 0xff, 0xee]).decodeItem(), CBOR.byteString([0xc0, 0xff, 0xee]))
        XCTAssertEqual(try! CBORDecoder(input: [0x5a, 0x00, 0x00, 0x00, 3, 0xc0, 0xff, 0xee]).decodeItem(), CBOR.byteString([0xc0, 0xff, 0xee]))
        XCTAssertEqual(try! CBORDecoder(input: [0x5b, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 3, 0xc0, 0xff, 0xee]).decodeItem(), CBOR.byteString([0xc0, 0xff, 0xee]))
        XCTAssertEqual(try! CBORDecoder(input: [0x5f, 0x58, 3, 0xc0, 0xff, 0xee, 0x43, 0xc0, 0xff, 0xee, 0xff]).decodeItem(), CBOR.byteString([0xc0, 0xff, 0xee, 0xc0, 0xff, 0xee]))
    }

    func testDecodeUtf8Strings() {
        XCTAssertEqual(try! CBORDecoder(input: [0x60]).decodeItem(), CBOR.utf8String(""))
        XCTAssertEqual(try! CBORDecoder(input: [0x61, 0x42]).decodeItem(), "B")
        XCTAssertEqual(try! CBORDecoder(input: [0x78, 0]).decodeItem(), "")
        XCTAssertEqual(try! CBORDecoder(input: [0x78, 1, 0x42]).decodeItem(), "B")
        XCTAssertEqual(try! CBORDecoder(input: [0x79, 0x00, 3, 0x41, 0x42, 0x43]).decodeItem(), CBOR.utf8String("ABC"))
        XCTAssertEqual(try! CBORDecoder(input: [0x7a, 0x00, 0x00, 0x00, 3, 0x41, 0x42, 0x43]).decodeItem(), "ABC")
        XCTAssertEqual(try! CBORDecoder(input: [0x7b, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 3, 0x41, 0x42, 0x43]).decodeItem(), "ABC")
        XCTAssertEqual(try! CBORDecoder(input: [0x7f, 0x78, 3, 0x41, 0x42, 0x43, 0x63, 0x41, 0x42, 0x43, 0xff]).decodeItem(), "ABCABC")
    }

    func testDecodeArrays() {
        XCTAssertEqual(try! CBORDecoder(input: [0x80]).decodeItem(), [])
        XCTAssertEqual(try! CBORDecoder(input: [0x82, 0x18, 1, 0x79, 0x00, 3, 0x41, 0x42, 0x43]).decodeItem(), [1, "ABC"])
        XCTAssertEqual(try! CBORDecoder(input: [0x98, 0]).decodeItem(), [])
        XCTAssertEqual(try! CBORDecoder(input: [0x98, 3, 0x18, 2, 0x18, 2, 0x79, 0x00, 3, 0x41, 0x42, 0x43, 0xff]).decodeItem(), [2, 2, "ABC"])
        XCTAssertEqual(try! CBORDecoder(input: [0x9f, 0x18, 255, 0x9b, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 2, 0x18, 1, 0x79, 0x00, 3, 0x41, 0x42, 0x43, 0x79, 0x00, 3, 0x41, 0x42, 0x43, 0xff]).decodeItem(), [255, [1, "ABC"], "ABC"])
    }

    func testDecodeMaps() {
        XCTAssertEqual(try! CBORDecoder(input: [0xa0]).decodeItem(), [:])
        XCTAssertEqual(try! CBORDecoder(input: [0xa1, 0x63, 0x6b, 0x65, 0x79, 0x37]).decodeItem()!["key"], -24)
        XCTAssertEqual(try! CBORDecoder(input: [0xb8, 1, 0x63, 0x6b, 0x65, 0x79, 0x81, 0x37]).decodeItem(), ["key" : [-24]])
        XCTAssertEqual(try! CBORDecoder(input: [0xbf, 0x63, 0x6b, 0x65, 0x79, 0xa1, 0x63, 0x6b, 0x65, 0x79, 0x37, 0xff]).decodeItem(), ["key" : ["key" : -24]])
    }

    func testDecodeTagged() {
        XCTAssertEqual(try! CBORDecoder(input: [0xc0, 0x79, 0x00, 3, 0x41, 0x42, 0x43]).decodeItem(), CBOR.tagged(.standardDateTimeString, "ABC"))
        XCTAssertEqual(try! CBORDecoder(input: [0xd8, 255, 0x79, 0x00, 3, 0x41, 0x42, 0x43]).decodeItem(), CBOR.tagged(.init(rawValue: 255), "ABC"))
        XCTAssertEqual(try! CBORDecoder(input: [0xdb, 255, 255, 255, 255, 255, 255, 255, 255, 0x79, 0x00, 3, 0x41, 0x42, 0x43]).decodeItem(), CBOR.tagged(.init(rawValue: UInt64.max), "ABC"))
        XCTAssertEqual(try! CBORDecoder(input: [0xdb, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 3, 0xbf, 0x63, 0x6b, 0x65, 0x79, 0xa1, 0x63, 0x6b, 0x65, 0x79, 0x37, 0xff]).decodeItem(), CBOR.tagged(.negativeBignum, ["key" : ["key" : -24]]))
    }

    func testDecodeSimple() {
        XCTAssertEqual(try! CBORDecoder(input: [0xe0]).decodeItem(), CBOR.simple(0))
        XCTAssertEqual(try! CBORDecoder(input: [0xf3]).decodeItem(), CBOR.simple(19))
        XCTAssertEqual(try! CBORDecoder(input: [0xf8, 19]).decodeItem(), CBOR.simple(19))
        XCTAssertEqual(try! CBORDecoder(input: [0xf4]).decodeItem(), false)
        XCTAssertEqual(try! CBORDecoder(input: [0xf5]).decodeItem(), true)
        XCTAssertEqual(try! CBORDecoder(input: [0xf6]).decodeItem(), CBOR.null)
        XCTAssertEqual(try! CBORDecoder(input: [0xf7]).decodeItem(), CBOR.undefined)
    }

    func testDecodeFloats() {
        XCTAssertEqual(try! CBORDecoder(input: [0xf9, 0xc4, 0x00]).decodeItem(), CBOR.half(-4.0))
        XCTAssertEqual(try! CBORDecoder(input: [0xf9, 0xfc, 0x00]).decodeItem(), CBOR.half(-Float.infinity))
        XCTAssertEqual(try! CBORDecoder(input: [0xfa, 0x47, 0xc3, 0x50, 0x00]).decodeItem(), 100000.0)
        XCTAssertEqual(try! CBORDecoder(input: [0xfa, 0x7f, 0x80, 0x00, 0x00]).decodeItem(), CBOR.float(Float.infinity))
        XCTAssertEqual(try! CBORDecoder(input: [0xfb, 0xc0, 0x10, 0x66, 0x66, 0x66, 0x66, 0x66, 0x66]).decodeItem(), CBOR.double(-4.1))
    }

    func testDecodeDates() {
        let dateOne = Date(timeIntervalSince1970: 1363896240)
        XCTAssertEqual(try! CBOR.decode([0xc1, 0x1a, 0x51, 0x4b, 0x67, 0xb0]), CBOR.date(dateOne))

        let dateTwo = Date(timeIntervalSince1970: 1363896240.5)
        XCTAssertEqual(try! CBOR.decode([0xc1, 0xfb, 0x41, 0xd4, 0x52, 0xd9, 0xec, 0x20, 0x00, 0x00]), CBOR.date(dateTwo))
    }

    func testDecodePerformance() {
        var data : ArraySlice<UInt8> = [0x9f]
        for i in (0..<255) {
            data.append(contentsOf: [0xbf, 0x63, 0x6b, 0x65, 0x79, 0xa1, 0x63, 0x6b, 0x65, 0x79, 0x18, UInt8(i), 0xff])
        }
        data.append(0xff)
        self.measure {
            _ = try! CBORDecoder(input: data).decodeItem()
        }
    }






    func testCBORCodableDecodeArrays() {
        let empty = try! CodableCBORDecoder().decode([String].self, from: Data([0x80]))
        XCTAssertEqual(empty, [])
        let oneTwoThree = try! CodableCBORDecoder().decode([Int].self, from: Data([0x83, 0x01, 0x02, 0x03]))
        XCTAssertEqual(oneTwoThree, [1, 2, 3])
        let lotsOfInts = try! CodableCBORDecoder().decode([Int].self, from: Data([0x98, 0x19, 0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08, 0x09, 0x0a, 0x0b, 0x0c, 0x0d, 0x0e, 0x0f, 0x10, 0x11, 0x12, 0x13, 0x14, 0x15, 0x16, 0x17, 0x18, 0x18, 0x18, 0x19]))
        XCTAssertEqual(lotsOfInts, [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25])
        let nestedSimple = try! CodableCBORDecoder().decode([[Int]].self, from: Data([0x83, 0x81, 0x01, 0x82, 0x02, 0x03, 0x82, 0x04, 0x05]))
        XCTAssertEqual(nestedSimple, [[1], [2, 3], [4, 5]])
    }

    func testCBORCodableDecodeBools() {
        let falseVal = try! CodableCBORDecoder().decode(Bool.self, from: Data([0xf4]))
        XCTAssertEqual(falseVal, false)
        let trueVal = try! CodableCBORDecoder().decode(Bool.self, from: Data([0xf5]))
        XCTAssertEqual(trueVal, true)
    }

    func testCBORCodableDecodeNull() {
        let decoded = try! CodableCBORDecoder().decode(Optional<String>.self, from: Data([0xf6]))
        XCTAssertNil(decoded)
    }

    func testCBORCodableDecodeInts() {
        // Less than 24
        let zero = try! CodableCBORDecoder().decode(Int.self, from: Data([0x00]))
        XCTAssertEqual(zero, 0)
        let eight = try! CodableCBORDecoder().decode(Int.self, from: Data([0x08]))
        XCTAssertEqual(eight, 8)
        let ten = try! CodableCBORDecoder().decode(Int.self, from: Data([0x0a]))
        XCTAssertEqual(ten, 10)
        let twentyThree = try! CodableCBORDecoder().decode(Int.self, from: Data([0x17]))
        XCTAssertEqual(twentyThree, 23)

        // Just bigger than 23
        let twentyFour = try! CodableCBORDecoder().decode(Int.self, from: Data([0x18, 0x18]))
        XCTAssertEqual(twentyFour, 24)
        let twentyFive = try! CodableCBORDecoder().decode(Int.self, from: Data([0x18, 0x19]))
        XCTAssertEqual(twentyFive, 25)

        // Bigger
        let hundred = try! CodableCBORDecoder().decode(Int.self, from: Data([0x18, 0x64]))
        XCTAssertEqual(hundred, 100)
        let thousand = try! CodableCBORDecoder().decode(Int.self, from: Data([0x19, 0x03, 0xe8]))
        XCTAssertEqual(thousand, 1_000)
        let million = try! CodableCBORDecoder().decode(Int.self, from: Data([0x1a, 0x00, 0x0f, 0x42, 0x40]))
        XCTAssertEqual(million, 1_000_000)
        let trillion = try! CodableCBORDecoder().decode(Int.self, from: Data([0x1b, 0x00, 0x00, 0x00, 0xe8, 0xd4, 0xa5, 0x10, 0x00]))
        XCTAssertEqual(trillion, 1_000_000_000_000)

        // TODO: Tagged byte strings for big numbers
        //        let bigNum = try! CodableCBORDecoder().decode(Int.self, from: Data([0x1b, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff]))
        //        XCTAssertEqual(bigNum, 18_446_744_073_709_551_615)
        //        let biggerNum = try! CodableCBORDecoder().decode(Int.self, from: Data([0x2c, 0x49, 0x01, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,]))
        //        XCTAssertEqual(biggerNum, 18_446_744_073_709_551_616)
    }

    func testCBORCodableDecodeNegativeInts() {
        // Less than 24
        let minusOne = try! CodableCBORDecoder().decode(Int.self, from: Data([0x20]))
        XCTAssertEqual(minusOne, -1)
        let minusTen = try! CodableCBORDecoder().decode(Int.self, from: Data([0x29]))
        XCTAssertEqual(minusTen, -10)

        // Bigger
        let minusHundred = try! CodableCBORDecoder().decode(Int.self, from: Data([0x38, 0x63]))
        XCTAssertEqual(minusHundred, -100)
        let minusThousand = try! CodableCBORDecoder().decode(Int.self, from: Data([0x39, 0x03, 0xe7]))
        XCTAssertEqual(minusThousand, -1_000)


        // TODO: Tagged byte strings for big numbers
        //        let bigNum = try! CodableCBORDecoder().decode(Int.self, from: Data([0x1b, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff]))
        //        XCTAssertEqual(bigNum, 18_446_744_073_709_551_615)
        //        let biggerNum = try! CodableCBORDecoder().decode(Int.self, from: Data([0x2c, 0x49, 0x01, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,]))
        //        XCTAssertEqual(biggerNum, 18_446_744_073_709_551_616)
    }

    func testCBORCodableDecodeStrings() {
        let empty = try! CodableCBORDecoder().decode(String.self, from: Data([0x60]))
        XCTAssertEqual(empty, "")
        let a = try! CodableCBORDecoder().decode(String.self, from: Data([0x61, 0x61]))
        XCTAssertEqual(a, "a")
        let IETF = try! CodableCBORDecoder().decode(String.self, from: Data([0x64, 0x49, 0x45, 0x54, 0x46]))
        XCTAssertEqual(IETF, "IETF")
        let quoteSlash = try! CodableCBORDecoder().decode(String.self, from: Data([0x62, 0x22, 0x5c]))
        XCTAssertEqual(quoteSlash, "\"\\")
        let littleUWithDiaeresis = try! CodableCBORDecoder().decode(String.self, from: Data([0x62, 0xc3, 0xbc]))
        XCTAssertEqual(littleUWithDiaeresis, "\u{00FC}")
    }

    func testCBORCodableDecodeMaps() {
        let empty = try! CodableCBORDecoder().decode([String: String].self, from: Data([0xa0]))
        XCTAssertEqual(empty, [:])
        let stringToString = try! CodableCBORDecoder().decode([String: String].self, from: Data([0xa5, 0x61, 0x61, 0x61, 0x41, 0x61, 0x62, 0x61, 0x42, 0x61, 0x63, 0x61, 0x43, 0x61, 0x64, 0x61, 0x44, 0x61, 0x65, 0x61, 0x45]))
        XCTAssertEqual(stringToString, ["a": "A", "b": "B", "c": "C", "d": "D", "e": "E"])

        // TODO: Allow non-String keys for maps
//        let oneTwoThreeFour = try! CodableCBORDecoder().decode([Int: Int].self, from: Data([0xa2, 0x01, 0x02, 0x03, 0x04]))
//        XCTAssertEqual(oneTwoThreeFour, [1: 2, 3: 4])
    }


//    func testCBORCodableDecodeUndefined() {
//        let decoded = try! CodableCBORDecoder().decode(Optional<String>.self, from: Data([0xf7]))
//        XCTAssertNil(decoded)
//    }

}

