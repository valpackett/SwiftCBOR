import XCTest
@testable import SwiftCBOR

class CBORDecoderTests: XCTestCase {

	func testDecodeNumbers() {
		for i in (0..<24) {
            XCTAssertEqual(try! CBORDecoder(input: [UInt8(i)]).decodeItem(), CBOR.unsignedInt(UInt(i)))
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
		XCTAssertEqual(try! CBORDecoder(input: [0xc0, 0x79, 0x00, 3, 0x41, 0x42, 0x43]).decodeItem(), CBOR.tagged(0, "ABC"))
		XCTAssertEqual(try! CBORDecoder(input: [0xd8, 255, 0x79, 0x00, 3, 0x41, 0x42, 0x43]).decodeItem(), CBOR.tagged(255, "ABC"))
		XCTAssertEqual(try! CBORDecoder(input: [0xdb, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 3, 0xbf, 0x63, 0x6b, 0x65, 0x79, 0xa1, 0x63, 0x6b, 0x65, 0x79, 0x37, 0xff]).decodeItem(), CBOR.tagged(3, ["key" : ["key" : -24]]))
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

}
