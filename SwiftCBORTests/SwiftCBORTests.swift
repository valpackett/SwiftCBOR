import XCTest
@testable import SwiftCBOR

class SwiftCBORTests: XCTestCase {

	func testDecodeNumbers() {
		for i in (0..<24) {
			XCTAssertEqual(try! CBORDecoder(input: [UInt8(i)]).decodeItem(), CBOR.PositiveInt(UInt(i)))
		}
		XCTAssertEqual(try! CBORDecoder(input: [0x18, 0xff]).decodeItem(), CBOR.PositiveInt(255))
		XCTAssertEqual(try! CBORDecoder(input: [0x19, 0x03, 0xe8]).decodeItem(), CBOR.PositiveInt(1000)) // Network byte order!
		XCTAssertEqual(try! CBORDecoder(input: [0x19, 0xff, 0xff]).decodeItem(), CBOR.PositiveInt(65535))
		do { try CBORDecoder(input: [0x19, 0xff]).decodeItem(); XCTAssertTrue(false) } catch { XCTAssertTrue(true) }
		XCTAssertEqual(try! CBORDecoder(input: [0x1a, 0x00, 0x0f, 0x42, 0x40]).decodeItem(), CBOR.PositiveInt(1000000))
		XCTAssertEqual(try! CBORDecoder(input: [0x1a, 0xff, 0xff, 0xff, 0xff]).decodeItem(), CBOR.PositiveInt(4294967295))
		do { try CBORDecoder(input: [0x1a]).decodeItem(); XCTAssertTrue(false) } catch { XCTAssertTrue(true) }
		XCTAssertEqual(try! CBORDecoder(input: [0x1b, 0x00, 0x00, 0x00, 0xe8, 0xd4, 0xa5, 0x10, 0x00]).decodeItem(), CBOR.PositiveInt(1000000000000))
		XCTAssertEqual(try! CBORDecoder(input: [0x1b, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff]).decodeItem(), CBOR.PositiveInt(18446744073709551615))
		do { try CBORDecoder(input: [0x1b, 0x00, 0x00]).decodeItem(); XCTAssertTrue(false) } catch { XCTAssertTrue(true) }

		XCTAssertEqual(try! CBORDecoder(input: [0x20]).decodeItem(), CBOR.NegativeInt(0))
		XCTAssertEqual(try! CBORDecoder(input: [0x21]).decodeItem(), CBOR.NegativeInt(1))
		XCTAssertEqual(try! CBORDecoder(input: [0x37]).decodeItem(), CBOR.NegativeInt(23))
		XCTAssertEqual(try! CBORDecoder(input: [0x38, 0xff]).decodeItem(), CBOR.NegativeInt(255))
		XCTAssertEqual(try! CBORDecoder(input: [0x39, 0x03, 0xe7]).decodeItem(), CBOR.NegativeInt(999))
		XCTAssertEqual(try! CBORDecoder(input: [0x3a, 0x00, 0x0f, 0x42, 0x3f]).decodeItem(), CBOR.NegativeInt(999999))
		XCTAssertEqual(try! CBORDecoder(input: [0x3b, 0x00, 0x00, 0x00, 0xe8, 0xd4, 0xa5, 0x0f, 0xff]).decodeItem(), CBOR.NegativeInt(999999999999))
	}

	func testDecodeByteStrings() {
		XCTAssertEqual(try! CBORDecoder(input: [0x40]).decodeItem(), CBOR.ByteString([]))
		XCTAssertEqual(try! CBORDecoder(input: [0x41, 0xf0]).decodeItem(), CBOR.ByteString([0xf0]))
		XCTAssertEqual(try! CBORDecoder(input: [0x57, 0xff, 0x00, 0xff, 0x00, 0xff, 0x00, 0xff, 0x00, 0xff, 0x00, 0xff, 0x00, 0xff, 0x00, 0xff, 0x00, 0xff, 0x00, 0xff, 0x00, 0xff, 0x00, 0xaa]).decodeItem(), CBOR.ByteString([0xff, 0x00, 0xff, 0x00, 0xff, 0x00, 0xff, 0x00, 0xff, 0x00, 0xff, 0x00, 0xff, 0x00, 0xff, 0x00, 0xff, 0x00, 0xff, 0x00, 0xff, 0x00, 0xaa]))
		XCTAssertEqual(try! CBORDecoder(input: [0x58, 0]).decodeItem(), CBOR.ByteString([]))
		XCTAssertEqual(try! CBORDecoder(input: [0x58, 1, 0xf0]).decodeItem(), CBOR.ByteString([0xf0]))
		XCTAssertEqual(try! CBORDecoder(input: [0x59, 0x00, 3, 0xc0, 0xff, 0xee]).decodeItem(), CBOR.ByteString([0xc0, 0xff, 0xee]))
		XCTAssertEqual(try! CBORDecoder(input: [0x5a, 0x00, 0x00, 0x00, 3, 0xc0, 0xff, 0xee]).decodeItem(), CBOR.ByteString([0xc0, 0xff, 0xee]))
		XCTAssertEqual(try! CBORDecoder(input: [0x5b, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 3, 0xc0, 0xff, 0xee]).decodeItem(), CBOR.ByteString([0xc0, 0xff, 0xee]))
		XCTAssertEqual(try! CBORDecoder(input: [0x5f, 0x58, 3, 0xc0, 0xff, 0xee, 0x43, 0xc0, 0xff, 0xee, 0xff]).decodeItem(), CBOR.ByteString([0xc0, 0xff, 0xee, 0xc0, 0xff, 0xee]))
	}

	func testDecodeUtf8Strings() {
		XCTAssertEqual(try! CBORDecoder(input: [0x60]).decodeItem(), CBOR.UTF8String(""))
		XCTAssertEqual(try! CBORDecoder(input: [0x61, 0x42]).decodeItem(), CBOR.UTF8String("B"))
		XCTAssertEqual(try! CBORDecoder(input: [0x78, 0]).decodeItem(), CBOR.UTF8String(""))
		XCTAssertEqual(try! CBORDecoder(input: [0x78, 1, 0x42]).decodeItem(), CBOR.UTF8String("B"))
		XCTAssertEqual(try! CBORDecoder(input: [0x79, 0x00, 3, 0x41, 0x42, 0x43]).decodeItem(), CBOR.UTF8String("ABC"))
		XCTAssertEqual(try! CBORDecoder(input: [0x7a, 0x00, 0x00, 0x00, 3, 0x41, 0x42, 0x43]).decodeItem(), CBOR.UTF8String("ABC"))
		XCTAssertEqual(try! CBORDecoder(input: [0x7b, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 3, 0x41, 0x42, 0x43]).decodeItem(), CBOR.UTF8String("ABC"))
		XCTAssertEqual(try! CBORDecoder(input: [0x7f, 0x78, 3, 0x41, 0x42, 0x43, 0x63, 0x41, 0x42, 0x43, 0xff]).decodeItem(), CBOR.UTF8String("ABCABC"))
	}

	func testDecodeArrays() {
		XCTAssertEqual(try! CBORDecoder(input: [0x80]).decodeItem(), CBOR.Array([]))
		XCTAssertEqual(try! CBORDecoder(input: [0x82, 0x18, 1, 0x79, 0x00, 3, 0x41, 0x42, 0x43]).decodeItem(),
			CBOR.Array([CBOR.PositiveInt(1), CBOR.UTF8String("ABC")]))
		XCTAssertEqual(try! CBORDecoder(input: [0x98, 0]).decodeItem(), CBOR.Array([]))
		XCTAssertEqual(try! CBORDecoder(input: [0x98, 3, 0x18, 2, 0x18, 2, 0x79, 0x00, 3, 0x41, 0x42, 0x43, 0xff]).decodeItem(),
			CBOR.Array([CBOR.PositiveInt(2), CBOR.PositiveInt(2), CBOR.UTF8String("ABC")]))
		XCTAssertEqual(try! CBORDecoder(input: [0x9f, 0x18, 255, 0x9b, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 2, 0x18, 1, 0x79, 0x00, 3, 0x41, 0x42, 0x43, 0x79, 0x00, 3, 0x41, 0x42, 0x43, 0xff]).decodeItem(),
			CBOR.Array([CBOR.PositiveInt(255), CBOR.Array([CBOR.PositiveInt(1), CBOR.UTF8String("ABC")]), CBOR.UTF8String("ABC")]))
	}

	func testDecodeMaps() {
		XCTAssertEqual(try! CBORDecoder(input: [0xa0]).decodeItem(), CBOR.Map([:]))
		XCTAssertEqual(try! CBORDecoder(input: [0xa1, 0x63, 0x6b, 0x65, 0x79, 0x37]).decodeItem(),
			CBOR.Map([CBOR.UTF8String("key") : CBOR.NegativeInt(23)]))
		XCTAssertEqual(try! CBORDecoder(input: [0xb8, 1, 0x63, 0x6b, 0x65, 0x79, 0x81, 0x37]).decodeItem(),
			CBOR.Map([CBOR.UTF8String("key") : CBOR.Array([CBOR.NegativeInt(23)])]))
		XCTAssertEqual(try! CBORDecoder(input: [0xbf, 0x63, 0x6b, 0x65, 0x79, 0xa1, 0x63, 0x6b, 0x65, 0x79, 0x37, 0xff]).decodeItem(),
			CBOR.Map([CBOR.UTF8String("key") : CBOR.Map([CBOR.UTF8String("key") : CBOR.NegativeInt(23)])]))
	}

	func testDecodePerformance() {
		var data : ArraySlice<UInt8> = [0x9f]
		for i in (0..<255) {
			data.appendContentsOf([0xbf, 0x63, 0x6b, 0x65, 0x79, 0xa1, 0x63, 0x6b, 0x65, 0x79, 0x18, UInt8(i), 0xff])
		}
		data.append(0xff)
		self.measureBlock {
			try! CBORDecoder(input: data).decodeItem()
		}
	}

}