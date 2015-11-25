import XCTest
@testable import SwiftCBOR

class SwiftCBORTests: XCTestCase {

	func testDecodeNumbers() {
		for i in (0..<24) {
			XCTAssertEqual(try! CBORDecoder(input: [UInt8(i)]).decodeItem() as? UInt, UInt(i))
		}
		XCTAssertEqual(try! CBORDecoder(input: [0x18, 0xff]).decodeItem() as? UInt, 255)
		XCTAssertEqual(try! CBORDecoder(input: [0x19, 0x03, 0xe8]).decodeItem() as? UInt, 1000) // Network byte order!
		XCTAssertEqual(try! CBORDecoder(input: [0x19, 0xff, 0xff]).decodeItem() as? UInt, 65535)
		do { try CBORDecoder(input: [0x19, 0xff]).decodeItem(); XCTAssertTrue(false) } catch { XCTAssertTrue(true) }
		XCTAssertEqual(try! CBORDecoder(input: [0x1a, 0x00, 0x0f, 0x42, 0x40]).decodeItem() as? UInt, 1000000)
		XCTAssertEqual(try! CBORDecoder(input: [0x1a, 0xff, 0xff, 0xff, 0xff]).decodeItem() as? UInt, 4294967295)
		do { try CBORDecoder(input: [0x1a]).decodeItem(); XCTAssertTrue(false) } catch { XCTAssertTrue(true) }
		XCTAssertEqual(try! CBORDecoder(input: [0x1b, 0x00, 0x00, 0x00, 0xe8, 0xd4, 0xa5, 0x10, 0x00]).decodeItem() as? UInt, 1000000000000)
		XCTAssertEqual(try! CBORDecoder(input: [0x1b, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff]).decodeItem() as? UInt, 18446744073709551615)
		do { try CBORDecoder(input: [0x1b, 0x00, 0x00]).decodeItem(); XCTAssertTrue(false) } catch { XCTAssertTrue(true) }

		XCTAssertEqual(try! CBORDecoder(input: [0x20]).decodeItem() as? Int, -1)
		XCTAssertEqual(try! CBORDecoder(input: [0x21]).decodeItem() as? Int, -2)
		XCTAssertEqual(try! CBORDecoder(input: [0x37]).decodeItem() as? Int, -24)
		XCTAssertEqual(try! CBORDecoder(input: [0x38, 0xff]).decodeItem() as? Int, -256)
		XCTAssertEqual(try! CBORDecoder(input: [0x39, 0x03, 0xe7]).decodeItem() as? Int, -1000)
		XCTAssertEqual(try! CBORDecoder(input: [0x3a, 0x00, 0x0f, 0x42, 0x3f]).decodeItem() as? Int, -1000000)
		XCTAssertEqual((try! CBORDecoder(input: [0x3b, 0x00, 0x00, 0x00, 0xe8, 0xd4, 0xa5, 0x0f, 0xff]).decodeItem() as! LargeNegativeInt).i, 999999999999)
	}

	func testDecodeByteStrings() {
		XCTAssertEqual(try! CBORDecoder(input: [0x40]).decodeItem() as! [UInt8], [])
		XCTAssertEqual(try! CBORDecoder(input: [0x41, 0xf0]).decodeItem() as! [UInt8], [0xf0])
		XCTAssertEqual(try! CBORDecoder(input: [0x57, 0xff, 0x00, 0xff, 0x00, 0xff, 0x00, 0xff, 0x00, 0xff, 0x00, 0xff, 0x00, 0xff, 0x00, 0xff, 0x00, 0xff, 0x00, 0xff, 0x00, 0xff, 0x00, 0xaa]).decodeItem() as! [UInt8], [0xff, 0x00, 0xff, 0x00, 0xff, 0x00, 0xff, 0x00, 0xff, 0x00, 0xff, 0x00, 0xff, 0x00, 0xff, 0x00, 0xff, 0x00, 0xff, 0x00, 0xff, 0x00, 0xaa])
		XCTAssertEqual(try! CBORDecoder(input: [0x58, 0]).decodeItem() as! [UInt8], [])
		XCTAssertEqual(try! CBORDecoder(input: [0x58, 1, 0xf0]).decodeItem() as! [UInt8], [0xf0])
		XCTAssertEqual(try! CBORDecoder(input: [0x59, 0x00, 3, 0xc0, 0xff, 0xee]).decodeItem() as! [UInt8], [0xc0, 0xff, 0xee])
		XCTAssertEqual(try! CBORDecoder(input: [0x5a, 0x00, 0x00, 0x00, 3, 0xc0, 0xff, 0xee]).decodeItem() as! [UInt8], [0xc0, 0xff, 0xee])
		XCTAssertEqual(try! CBORDecoder(input: [0x5b, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 3, 0xc0, 0xff, 0xee]).decodeItem() as! [UInt8], [0xc0, 0xff, 0xee])
		XCTAssertEqual(try! CBORDecoder(input: [0x5f, 0x58, 3, 0xc0, 0xff, 0xee, 0x43, 0xc0, 0xff, 0xee, 0xff]).decodeItem() as! [UInt8], [0xc0, 0xff, 0xee, 0xc0, 0xff, 0xee])
	}

	func testDecodeUtf8Strings() {
		XCTAssertEqual(try! CBORDecoder(input: [0x60]).decodeItem() as! String, "")
		XCTAssertEqual(try! CBORDecoder(input: [0x61, 0x42]).decodeItem() as! String, "B")
		XCTAssertEqual(try! CBORDecoder(input: [0x78, 0]).decodeItem() as! String, "")
		XCTAssertEqual(try! CBORDecoder(input: [0x78, 1, 0x42]).decodeItem() as! String, "B")
		XCTAssertEqual(try! CBORDecoder(input: [0x79, 0x00, 3, 0x41, 0x42, 0x43]).decodeItem() as! String, "ABC")
		XCTAssertEqual(try! CBORDecoder(input: [0x7a, 0x00, 0x00, 0x00, 3, 0x41, 0x42, 0x43]).decodeItem() as! String, "ABC")
		XCTAssertEqual(try! CBORDecoder(input: [0x7b, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 3, 0x41, 0x42, 0x43]).decodeItem() as! String, "ABC")
		XCTAssertEqual(try! CBORDecoder(input: [0x7f, 0x78, 3, 0x41, 0x42, 0x43, 0x63, 0x41, 0x42, 0x43, 0xff]).decodeItem() as! String, "ABCABC")
	}

	func testDecodeArrays() {
		XCTAssertEqual((try! CBORDecoder(input: [0x80]).decodeItem() as! [Any]).count, 0)
		let r1 = try! CBORDecoder(input: [0x82, 0x18, 1, 0x79, 0x00, 3, 0x41, 0x42, 0x43]).decodeItem() as! [Any]
		XCTAssertEqual(r1[0] as? UInt, 1)
		XCTAssertEqual(r1[1] as? String, "ABC")
		XCTAssertEqual((try! CBORDecoder(input: [0x98, 0]).decodeItem() as! [Any]).count, 0)
		let r2 = try! CBORDecoder(input: [0x98, 3, 0x18, 2, 0x18, 2, 0x79, 0x00, 3, 0x41, 0x42, 0x43, 0xff]).decodeItem() as! [Any]
		XCTAssertEqual(r2[0] as? UInt, 2)
		XCTAssertEqual(r2[1] as? UInt, 2)
		XCTAssertEqual(r2[2] as? String, "ABC")
		let rf = try! CBORDecoder(input: [0x9f, 0x18, 255, 0x9b, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 2, 0x18, 1, 0x79, 0x00, 3, 0x41, 0x42, 0x43, 0x79, 0x00, 3, 0x41, 0x42, 0x43, 0xff]).decodeItem() as! [Any]
		XCTAssertEqual(rf[0] as? UInt, 255)
		XCTAssertEqual((rf[1] as! [Any])[0] as? UInt, 1)
		XCTAssertEqual((rf[1] as! [Any])[1] as? String, "ABC")
		XCTAssertEqual(rf[2] as? String, "ABC")
	}

	func testDecodeMaps() {
		XCTAssertEqual((try! CBORDecoder(input: [0xa0]).decodeItem() as! [String : Any]).count, 0)
		let r1 = try! CBORDecoder(input: [0xa1, 0x63, 0x6b, 0x65, 0x79, 0x37]).decodeItem() as! [String : Any]
		XCTAssertEqual(r1["key"] as? Int, -24)
		let r2 = try! CBORDecoder(input: [0xb8, 1, 0x63, 0x6b, 0x65, 0x79, 0x81, 0x37]).decodeItem() as! [String : Any]
		XCTAssertEqual((r2["key"] as! [Any])[0] as? Int, -24)
		let rf = try! CBORDecoder(input: [0xbf, 0x63, 0x6b, 0x65, 0x79, 0xa1, 0x63, 0x6b, 0x65, 0x79, 0x37, 0xff]).decodeItem() as! [String : Any]
		XCTAssertEqual((rf["key"] as! [String : Any])["key"] as? Int, -24)
	}

	func testPerformanceExample() {
		self.measureBlock {
		}
	}

}