import XCTest
@testable import SwiftCBOR

class CBORCodableRoundtripTests: XCTestCase {
    static var allTests = [
        ("testSimpleStruct", testSimpleStruct),
        ("testSimpleStructsInArray", testSimpleStructsInArray),
        ("testSimpleStructsAsValuesInMap", testSimpleStructsAsValuesInMap),
        ("testSimpleStructsAsKeysInMap", testSimpleStructsAsKeysInMap),
        ("testNil", testNil),
        ("testBools", testBools),
        ("testInts", testInts),
        ("testNegativeInts", testNegativeInts),
        ("testStrings", testStrings),
        ("testArrays", testArrays),
        ("testMaps", testMaps),
        ("testWrappedStruct", testWrappedStruct),
    ]

    struct MyStruct: Codable, Equatable, Hashable {
        let age: Int
        let name: String
    }

    func testSimpleStruct() {
        let encoded = try! CBOREncoder().encode(MyStruct(age: 27, name: "Ham"))
        let decoded = try! CBORDecoder().decode(MyStruct.self, from: encoded)
        XCTAssertEqual(decoded, MyStruct(age: 27, name: "Ham"))
    }

    func testSimpleStructsInArray() {
        let encoded = try! CBOREncoder().encode([
            MyStruct(age: 27, name: "Ham"),
            MyStruct(age: 24, name: "Greg")
        ])
        let decoded = try! CBORDecoder().decode([MyStruct].self, from: encoded)
        XCTAssertEqual(decoded, [MyStruct(age: 27, name: "Ham"), MyStruct(age: 24, name: "Greg")])
    }

    func testSimpleStructsAsValuesInMap() {
        let encoded = try! CBOREncoder().encode([
            "Ham": MyStruct(age: 27, name: "Ham"),
            "Greg": MyStruct(age: 24, name: "Greg")
        ])
        let decoded = try! CBORDecoder().decode([String: MyStruct].self, from: encoded)
        XCTAssertEqual(
            decoded,
            [
                "Ham": MyStruct(age: 27, name: "Ham"),
                "Greg": MyStruct(age: 24, name: "Greg")
            ]
        )
    }

    func testSimpleStructsAsKeysInMap() {
        let encoded = try! CBOREncoder().encode([
            MyStruct(age: 27, name: "Ham"): "Ham",
            MyStruct(age: 24, name: "Greg"): "Greg"
        ])
        let decoded = try! CBORDecoder().decode([MyStruct: String].self, from: encoded)
        XCTAssertEqual(
            decoded,
            [
                MyStruct(age: 27, name: "Ham"): "Ham",
                MyStruct(age: 24, name: "Greg"): "Greg"
            ]
        )
    }

    func testNil() {
        let nilValue = try! CBOREncoder().encode(Optional<String>(nil))
        XCTAssertThrowsError(try CBORDecoder().decode(String.self, from: nilValue))
        XCTAssertNil(try CBORDecoder().decodeIfPresent(String.self, from: nilValue))
    }

    func testBools() {
        let falseVal = try! CBOREncoder().encode(false)
        let falseValDecoded = try! CBORDecoder().decode(Bool.self, from: falseVal)
        XCTAssertFalse(falseValDecoded)
        let trueVal = try! CBOREncoder().encode(true)
        let trueValDecoded = try! CBORDecoder().decode(Bool.self, from: trueVal)
        XCTAssertTrue(trueValDecoded)
    }

    func testInts() {
        // Less than 24
        let zero = try! CBOREncoder().encode(0)
        let zeroDecoded = try! CBORDecoder().decode(Int.self, from: zero)
        XCTAssertEqual(zeroDecoded, 0)
        let eight = try! CBOREncoder().encode(8)
        let eightDecoded = try! CBORDecoder().decode(Int.self, from: eight)
        XCTAssertEqual(eightDecoded, 8)
        let ten = try! CBOREncoder().encode(10)
        let tenDecoded = try! CBORDecoder().decode(Int.self, from: ten)
        XCTAssertEqual(tenDecoded, 10)
        let twentyThree = try! CBOREncoder().encode(23)
        let twentyThreeDecoded = try! CBORDecoder().decode(Int.self, from: twentyThree)
        XCTAssertEqual(twentyThreeDecoded, 23)

        // Just bigger than 23
        let twentyFour = try! CBOREncoder().encode(24)
        let twentyFourDecoded = try! CBORDecoder().decode(Int.self, from: twentyFour)
        XCTAssertEqual(twentyFourDecoded, 24)
        let twentyFive = try! CBOREncoder().encode(25)
        let twentyFiveDecoded = try! CBORDecoder().decode(Int.self, from: twentyFive)
        XCTAssertEqual(twentyFiveDecoded, 25)

        // Bigger
        let hundred = try! CBOREncoder().encode(100)
        let hundredDecoded = try! CBORDecoder().decode(Int.self, from: hundred)
        XCTAssertEqual(hundredDecoded, 100)
        let thousand = try! CBOREncoder().encode(1_000)
        let thousandDecoded = try! CBORDecoder().decode(Int.self, from: thousand)
        XCTAssertEqual(thousandDecoded, 1_000)
        let million = try! CBOREncoder().encode(1_000_000)
        let millionDecoded = try! CBORDecoder().decode(Int.self, from: million)
        XCTAssertEqual(millionDecoded, 1_000_000)
        let trillion = try! CBOREncoder().encode(1_000_000_000_000)
        let trillionDecoded = try! CBORDecoder().decode(Int.self, from: trillion)
        XCTAssertEqual(trillionDecoded, 1_000_000_000_000)

        // TODO: Tagged byte strings for big numbers
//        let bigNum = try! CBORDecoder().decode(Int.self, from: Data([0x1b, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff]))
//        XCTAssertEqual(bigNum, 18_446_744_073_709_551_615)
//        let biggerNum = try! CBORDecoder().decode(Int.self, from: Data([0x2c, 0x49, 0x01, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,]))
//        XCTAssertEqual(biggerNum, 18_446_744_073_709_551_616)
    }

    func testNegativeInts() {
        // Less than 24
        let minusOne = try! CBOREncoder().encode(-1)
        let minusOneDecoded = try! CBORDecoder().decode(Int.self, from: minusOne)
        XCTAssertEqual(minusOneDecoded, -1)
        let minusTen = try! CBOREncoder().encode(-10)
        let minusTenDecoded = try! CBORDecoder().decode(Int.self, from: minusTen)
        XCTAssertEqual(minusTenDecoded, -10)

        // Bigger
        let minusHundred = try! CBOREncoder().encode(-100)
        let minusHundredDecoded = try! CBORDecoder().decode(Int.self, from: minusHundred)
        XCTAssertEqual(minusHundredDecoded, -100)
        let minusThousand = try! CBOREncoder().encode(-1_000)
        let minusThousandDecoded = try! CBORDecoder().decode(Int.self, from: minusThousand)
        XCTAssertEqual(minusThousandDecoded, -1_000)

        // TODO: Tagged byte strings for big numbers
//        let bigNum = try! CBORDecoder().decode(Int.self, from: Data([0x1b, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff]))
//        XCTAssertEqual(bigNum, 18_446_744_073_709_551_615)
//        let biggerNum = try! CBORDecoder().decode(Int.self, from: Data([0x2c, 0x49, 0x01, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,]))
//        XCTAssertEqual(biggerNum, 18_446_744_073_709_551_616)
    }

    func testStrings() {
        let empty = try! CBOREncoder().encode("")
        let emptyDecoded = try! CBORDecoder().decode(String.self, from: empty)
        XCTAssertEqual(emptyDecoded, "")
        let a = try! CBOREncoder().encode("a")
        let aDecoded = try! CBORDecoder().decode(String.self, from: a)
        XCTAssertEqual(aDecoded, "a")
        let IETF = try! CBOREncoder().encode("IETF")
        let IETFDecoded = try! CBORDecoder().decode(String.self, from: IETF)
        XCTAssertEqual(IETFDecoded, "IETF")
        let quoteSlash = try! CBOREncoder().encode("\"\\")
        let quoteSlashDecoded = try! CBORDecoder().decode(String.self, from: quoteSlash)
        XCTAssertEqual(quoteSlashDecoded, "\"\\")
        let littleUWithDiaeresis = try! CBOREncoder().encode("\u{00FC}")
        let littleUWithDiaeresisDecoded = try! CBORDecoder().decode(String.self, from: littleUWithDiaeresis)
        XCTAssertEqual(littleUWithDiaeresisDecoded, "\u{00FC}")
    }

    func testArrays() {
        let empty = try! CBOREncoder().encode([String]())
        let emptyDecoded = try! CBORDecoder().decode([String].self, from: empty)
        XCTAssertEqual(emptyDecoded, [])
        let oneTwoThree = try! CBOREncoder().encode([1, 2, 3])
        let oneTwoThreeDecoded = try! CBORDecoder().decode([Int].self, from: oneTwoThree)
        XCTAssertEqual(oneTwoThreeDecoded, [1, 2, 3])
        let lotsOfInts = try! CBOREncoder().encode([1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25])
        let lotsOfIntsDecoded = try! CBORDecoder().decode([Int].self, from: lotsOfInts)
        XCTAssertEqual(lotsOfIntsDecoded, [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25])
        let nestedSimple = try! CBOREncoder().encode([[1], [2, 3], [4, 5]])
        let nestedSimpleDecoded = try! CBORDecoder().decode([[Int]].self, from: nestedSimple)
        XCTAssertEqual(nestedSimpleDecoded, [[1], [2, 3], [4, 5]])
    }

    func testMaps() {
        let empty = try! CBOREncoder().encode([String: String]())
        let emptyDecoded = try! CBORDecoder().decode([String: String].self, from: empty)
        XCTAssertEqual(emptyDecoded, [:])
        let stringToString = try! CBOREncoder().encode(["a": "A", "b": "B", "c": "C", "d": "D", "e": "E"])
        let stringToStringDecoded = try! CBORDecoder().decode([String: String].self, from: stringToString)
        XCTAssertEqual(stringToStringDecoded, ["a": "A", "b": "B", "c": "C", "d": "D", "e": "E"])
        let oneTwoThreeFour = try! CBOREncoder().encode([1: 2, 3: 4])
        let oneTwoThreeFourDecoded = try! CBORDecoder().decode([Int: Int].self, from: oneTwoThreeFour)
        XCTAssertEqual(oneTwoThreeFourDecoded, [1: 2, 3: 4])
    }

    func testWrappedStruct() {
        struct Wrapped<T: Codable>: Decodable {
            let _id: String
            let value: T

            private enum CodingKeys: String, CodingKey {
                case _id
            }

            init(from decoder: Decoder) throws {
                let container = try decoder.container(keyedBy: CodingKeys.self)

                _id = try container.decode(String.self, forKey: ._id)
                value = try T(from: decoder)
            }
        }

        struct BasicCar: Codable {
            let color: String
            let age: Int
            let data: Data
        }

        struct Car: Codable {
            let _id: String
            let color: String
            let age: Int
            let data: Data
        }

        // Generate some random Data
        let randomBytes = (1...4).map { _ in UInt8.random(in: 0...UInt8.max) }
        let data = Data(randomBytes)

        let car = Car(
            _id: "5caf23633337661721236cfa",
            color: "Red",
            age: 56,
            data: data
        )

        let encodedCar = try! CBOREncoder().encode(car)
        let decoded = try! CBORDecoder().decode(Wrapped<BasicCar>.self, from: encodedCar)

        XCTAssertEqual(decoded._id, car._id)
        XCTAssertEqual(decoded.value.color, car.color)
        XCTAssertEqual(decoded.value.age, car.age)
        XCTAssertEqual(decoded.value.data, data)
    }
}
