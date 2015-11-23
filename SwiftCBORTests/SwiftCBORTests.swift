import XCTest
@testable import SwiftCBOR

class SwiftCBORTests: XCTestCase {
	
	override func setUp() {
		super.setUp()
	}
	
	override func tearDown() {
		super.tearDown()
	}
	
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
	
	func testPerformanceExample() {
		self.measureBlock {
		}
	}
	
}