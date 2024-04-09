import XCTest
import OrderedCollections
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

        let nestedMap: OrderedDictionary<CBOR, CBOR> = [
            "joe": "schmoe",
            "age": 56
        ]

        cbor["tags"]?[2] = CBOR.map(nestedMap)
        XCTAssertEqual(cbor["tags"]?[2], CBOR.map(nestedMap))
    }
}
