import XCTest
@testable import SwiftCBOR

class CBORTests: XCTestCase {
    func testSubscriptSetter() {
        let dictionary: [String: Any] = [
            "foo": 1,
            "bar": "a",
            "zwii": "hd",
            "tags": [
                "a": "1",
                "b": 2
            ]
        ]

        let cborEncoded: [UInt8] = try! CBOR.encodeMap(dictionary)
        var cbor = try! CBOR.decode(cborEncoded)!
        cbor["foo"] = "changed"
        XCTAssertEqual(cbor["foo"], "changed")
    }

    func testNestedSubscriptSetter() {
        let dictionary: [String: Any] = [
            "foo": 1,
            "bar": "a",
            "zwii": "hd",
            "tags": [
                "a": "1",
                "b": 2
            ]
        ]

        let cborEncoded: [UInt8] = try! CBOR.encodeMap(dictionary)
        var cbor = try! CBOR.decode(cborEncoded)!
        cbor["tags"]?[2] = "changed"
        XCTAssertEqual(cbor["tags"]?[2], "changed")
    }

    func testNestedSubscriptSetterWithNewMap() {
        let dictionary: [String: Any] = [
            "foo": 1,
            "bar": "a",
            "zwii": "hd",
            "tags": [
                "a": "1",
                "b": 2
            ]
        ]

        let cborEncoded: [UInt8] = try! CBOR.encodeMap(dictionary)
        var cbor = try! CBOR.decode(cborEncoded)!

        let nestedMap: [CBOR: CBOR] = [
            "joe": "schmoe",
            "age": 56
        ]

        cbor["tags"]?[2] = CBOR.map(nestedMap)
        XCTAssertEqual(cbor["tags"]?[2], CBOR.map(nestedMap))
    }

    func testSubscriptSetterWithNilOnMap() {
        // Test that setting a map value to nil removes the key
        var cbor = CBOR.map(["foo": CBOR.unsignedInt(1), "bar": CBOR.utf8String("test")])

        XCTAssertEqual(cbor["foo"], CBOR.unsignedInt(1))

        // Setting to nil should remove the key
        cbor["foo"] = nil

        XCTAssertNil(cbor["foo"])
        XCTAssertEqual(cbor["bar"], CBOR.utf8String("test"))
    }

    func testSubscriptSetterWithNilOnArray() {
        // Test that setting an array element to nil sets it to CBOR.null
        var cbor = CBOR.array([CBOR.unsignedInt(1), CBOR.unsignedInt(2), CBOR.unsignedInt(3)])

        // Setting to nil should not crash and should set to CBOR.null
        cbor[1] = nil

        // Element should be set to null, others unchanged
        XCTAssertEqual(cbor[0], CBOR.unsignedInt(1))
        XCTAssertEqual(cbor[1], CBOR.null)
        XCTAssertEqual(cbor[2], CBOR.unsignedInt(3))
    }

    func testSubscriptSetterWithValidValue() {
        // Test that setting with a valid value still works
        var cbor = CBOR.array([CBOR.unsignedInt(1), CBOR.unsignedInt(2)])

        cbor[1] = CBOR.utf8String("changed")

        XCTAssertEqual(cbor[0], CBOR.unsignedInt(1))
        XCTAssertEqual(cbor[1], CBOR.utf8String("changed"))
    }
}
