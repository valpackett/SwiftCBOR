import XCTest
@testable import SwiftCBOR

class CBORTests: XCTestCase {
    func testByteStringHashMatchesDJB2() {
        let bytes: [UInt8] = [0, 1, 2, 127, 128, 255, 42]
        let hash = bytes.reduce(5381) { (($0 << 5) &+ $0) &+ Int($1) }

        var expectedHasher = Hasher()
        hash.hash(into: &expectedHasher)
        var actualHasher = Hasher()
        CBOR.byteString(bytes).hash(into: &actualHasher)

        XCTAssertEqual(actualHasher.finalize(), expectedHasher.finalize())
    }

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
}
