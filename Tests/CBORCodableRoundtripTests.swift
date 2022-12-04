import XCTest
import Foundation
@testable import SwiftCBOR

class CBORCodableRoundtripTests: XCTestCase {
    struct MyStruct: Codable, Equatable, Hashable {
        let age: Int
        let name: String
    }

    func testSimpleStruct() {
        let encoded = try! CodableCBOREncoder().encode(MyStruct(age: 27, name: "Ham"))
        let decoded = try! CodableCBORDecoder().decode(MyStruct.self, from: encoded)
        XCTAssertEqual(decoded, MyStruct(age: 27, name: "Ham"))
    }

    func testSimpleStructsInArray() {
        let encoded = try! CodableCBOREncoder().encode([
            MyStruct(age: 27, name: "Ham"),
            MyStruct(age: 24, name: "Greg")
        ])
        let decoded = try! CodableCBORDecoder().decode([MyStruct].self, from: encoded)
        XCTAssertEqual(decoded, [MyStruct(age: 27, name: "Ham"), MyStruct(age: 24, name: "Greg")])
    }

    func testSimpleStructsAsValuesInMap() {
        let encoded = try! CodableCBOREncoder().encode([
            "Ham": MyStruct(age: 27, name: "Ham"),
            "Greg": MyStruct(age: 24, name: "Greg")
        ])
        let decoded = try! CodableCBORDecoder().decode([String: MyStruct].self, from: encoded)
        XCTAssertEqual(
            decoded,
            [
                "Ham": MyStruct(age: 27, name: "Ham"),
                "Greg": MyStruct(age: 24, name: "Greg")
            ]
        )
    }

    func testSimpleStructsAsKeysInMap() {
        let encoded = try! CodableCBOREncoder().encode([
            MyStruct(age: 27, name: "Ham"): "Ham",
            MyStruct(age: 24, name: "Greg"): "Greg"
        ])
        let decoded = try! CodableCBORDecoder().decode([MyStruct: String].self, from: encoded)
        XCTAssertEqual(
            decoded,
            [
                MyStruct(age: 27, name: "Ham"): "Ham",
                MyStruct(age: 24, name: "Greg"): "Greg"
            ]
        )
    }

    func testNil() {
        let nilValue = try! CodableCBOREncoder().encode(Optional<String>(nil))
        let nilDecoded = try! CodableCBORDecoder().decode(Optional<String>.self, from: nilValue)
        XCTAssertNil(nilDecoded)
    }

    func testBools() {
        let falseVal = try! CodableCBOREncoder().encode(false)
        let falseValDecoded = try! CodableCBORDecoder().decode(Bool.self, from: falseVal)
        XCTAssertFalse(falseValDecoded)
        let trueVal = try! CodableCBOREncoder().encode(true)
        let trueValDecoded = try! CodableCBORDecoder().decode(Bool.self, from: trueVal)
        XCTAssertTrue(trueValDecoded)
    }

    func testInts() {
        // Less than 24
        let zero = try! CodableCBOREncoder().encode(0)
        let zeroDecoded = try! CodableCBORDecoder().decode(Int.self, from: zero)
        XCTAssertEqual(zeroDecoded, 0)
        let eight = try! CodableCBOREncoder().encode(8)
        let eightDecoded = try! CodableCBORDecoder().decode(Int.self, from: eight)
        XCTAssertEqual(eightDecoded, 8)
        let ten = try! CodableCBOREncoder().encode(10)
        let tenDecoded = try! CodableCBORDecoder().decode(Int.self, from: ten)
        XCTAssertEqual(tenDecoded, 10)
        let twentyThree = try! CodableCBOREncoder().encode(23)
        let twentyThreeDecoded = try! CodableCBORDecoder().decode(Int.self, from: twentyThree)
        XCTAssertEqual(twentyThreeDecoded, 23)

        // Just bigger than 23
        let twentyFour = try! CodableCBOREncoder().encode(24)
        let twentyFourDecoded = try! CodableCBORDecoder().decode(Int.self, from: twentyFour)
        XCTAssertEqual(twentyFourDecoded, 24)
        let twentyFive = try! CodableCBOREncoder().encode(25)
        let twentyFiveDecoded = try! CodableCBORDecoder().decode(Int.self, from: twentyFive)
        XCTAssertEqual(twentyFiveDecoded, 25)

        // Bigger
        let hundred = try! CodableCBOREncoder().encode(100)
        let hundredDecoded = try! CodableCBORDecoder().decode(Int.self, from: hundred)
        XCTAssertEqual(hundredDecoded, 100)
        let thousand = try! CodableCBOREncoder().encode(1_000)
        let thousandDecoded = try! CodableCBORDecoder().decode(Int.self, from: thousand)
        XCTAssertEqual(thousandDecoded, 1_000)
        let million = try! CodableCBOREncoder().encode(1_000_000)
        let millionDecoded = try! CodableCBORDecoder().decode(Int.self, from: million)
        XCTAssertEqual(millionDecoded, 1_000_000)
        let trillion = try! CodableCBOREncoder().encode(1_000_000_000_000)
        let trillionDecoded = try! CodableCBORDecoder().decode(Int.self, from: trillion)
        XCTAssertEqual(trillionDecoded, 1_000_000_000_000)

        // TODO: Tagged byte strings for big numbers
//        let bigNum = try! CodableCBORDecoder().decode(Int.self, from: Data([0x1b, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff]))
//        XCTAssertEqual(bigNum, 18_446_744_073_709_551_615)
//        let biggerNum = try! CodableCBORDecoder().decode(Int.self, from: Data([0x2c, 0x49, 0x01, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,]))
//        XCTAssertEqual(biggerNum, 18_446_744_073_709_551_616)
    }

    func testNegativeInts() {
        // Less than 24
        let minusOne = try! CodableCBOREncoder().encode(-1)
        let minusOneDecoded = try! CodableCBORDecoder().decode(Int.self, from: minusOne)
        XCTAssertEqual(minusOneDecoded, -1)
        let minusTen = try! CodableCBOREncoder().encode(-10)
        let minusTenDecoded = try! CodableCBORDecoder().decode(Int.self, from: minusTen)
        XCTAssertEqual(minusTenDecoded, -10)

        // Bigger
        let minusHundred = try! CodableCBOREncoder().encode(-100)
        let minusHundredDecoded = try! CodableCBORDecoder().decode(Int.self, from: minusHundred)
        XCTAssertEqual(minusHundredDecoded, -100)
        let minusThousand = try! CodableCBOREncoder().encode(-1_000)
        let minusThousandDecoded = try! CodableCBORDecoder().decode(Int.self, from: minusThousand)
        XCTAssertEqual(minusThousandDecoded, -1_000)

        // TODO: Tagged byte strings for big numbers
//        let bigNum = try! CodableCBORDecoder().decode(Int.self, from: Data([0x1b, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff]))
//        XCTAssertEqual(bigNum, 18_446_744_073_709_551_615)
//        let biggerNum = try! CodableCBORDecoder().decode(Int.self, from: Data([0x2c, 0x49, 0x01, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,]))
//        XCTAssertEqual(biggerNum, 18_446_744_073_709_551_616)
    }

    func testStrings() {
        let empty = try! CodableCBOREncoder().encode("")
        let emptyDecoded = try! CodableCBORDecoder().decode(String.self, from: empty)
        XCTAssertEqual(emptyDecoded, "")
        let a = try! CodableCBOREncoder().encode("a")
        let aDecoded = try! CodableCBORDecoder().decode(String.self, from: a)
        XCTAssertEqual(aDecoded, "a")
        let IETF = try! CodableCBOREncoder().encode("IETF")
        let IETFDecoded = try! CodableCBORDecoder().decode(String.self, from: IETF)
        XCTAssertEqual(IETFDecoded, "IETF")
        let quoteSlash = try! CodableCBOREncoder().encode("\"\\")
        let quoteSlashDecoded = try! CodableCBORDecoder().decode(String.self, from: quoteSlash)
        XCTAssertEqual(quoteSlashDecoded, "\"\\")
        let littleUWithDiaeresis = try! CodableCBOREncoder().encode("\u{00FC}")
        let littleUWithDiaeresisDecoded = try! CodableCBORDecoder().decode(String.self, from: littleUWithDiaeresis)
        XCTAssertEqual(littleUWithDiaeresisDecoded, "\u{00FC}")
    }

    func testArrays() {
        let empty = try! CodableCBOREncoder().encode([String]())
        let emptyDecoded = try! CodableCBORDecoder().decode([String].self, from: empty)
        XCTAssertEqual(emptyDecoded, [])
        let oneTwoThree = try! CodableCBOREncoder().encode([1, 2, 3])
        let oneTwoThreeDecoded = try! CodableCBORDecoder().decode([Int].self, from: oneTwoThree)
        XCTAssertEqual(oneTwoThreeDecoded, [1, 2, 3])
        let lotsOfInts = try! CodableCBOREncoder().encode([1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25])
        let lotsOfIntsDecoded = try! CodableCBORDecoder().decode([Int].self, from: lotsOfInts)
        XCTAssertEqual(lotsOfIntsDecoded, [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25])
        let nestedSimple = try! CodableCBOREncoder().encode([[1], [2, 3], [4, 5]])
        let nestedSimpleDecoded = try! CodableCBORDecoder().decode([[Int]].self, from: nestedSimple)
        XCTAssertEqual(nestedSimpleDecoded, [[1], [2, 3], [4, 5]])
    }

    func testMaps() {
        let empty = try! CodableCBOREncoder().encode([String: String]())
        let emptyDecoded = try! CodableCBORDecoder().decode([String: String].self, from: empty)
        XCTAssertEqual(emptyDecoded, [:])
        let stringToString = try! CodableCBOREncoder().encode(["a": "A", "b": "B", "c": "C", "d": "D", "e": "E"])
        let stringToStringDecoded = try! CodableCBORDecoder().decode([String: String].self, from: stringToString)
        XCTAssertEqual(stringToStringDecoded, ["a": "A", "b": "B", "c": "C", "d": "D", "e": "E"])
        let intKeyedMap = [1: 2, 3: 4]
        let oneTwoThreeFour = try! CodableCBOREncoder().encode(intKeyedMap)
        let oneTwoThreeFourDecoded = try! CodableCBORDecoder().decode([Int: Int].self, from: oneTwoThreeFour)
        XCTAssertEqual(oneTwoThreeFourDecoded, intKeyedMap)

        let encoder = CodableCBOREncoder()
        encoder.forbidNonStringMapKeys = true
        XCTAssertThrowsError(try encoder.encode(intKeyedMap)) { err in
            XCTAssertEqual(err as! CBOREncoderError, CBOREncoderError.nonStringKeyInMap)
        }
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

        let encodedCar = try! CodableCBOREncoder().encode(car)
        let decoded = try! CodableCBORDecoder().decode(Wrapped<BasicCar>.self, from: encodedCar)

        XCTAssertEqual(decoded._id, car._id)
        XCTAssertEqual(decoded.value.color, car.color)
        XCTAssertEqual(decoded.value.age, car.age)
        XCTAssertEqual(decoded.value.data, data)
    }

    func testStructWithFloat() {
        struct MenuItemWithFloatOrdinal: Codable  {
            var _id: String
            var category: String
            var ordinal: Float
        }

        let menuItem = MenuItemWithFloatOrdinal(
            _id: "aaa",
            category: "cake",
            ordinal: 12
        )

        let encoded = try! CodableCBOREncoder().encode(menuItem)
        let decoded = try! CodableCBORDecoder().decode(MenuItemWithFloatOrdinal.self, from: encoded)

        XCTAssertEqual(decoded._id, menuItem._id)
        XCTAssertEqual(decoded.category, menuItem.category)
        XCTAssertEqual(decoded.ordinal, menuItem.ordinal)
    }

    func testStructContainingEnum() {
        enum Status: Codable {
             case done, underway, open
        }

        struct Order: Codable {
            var status: Status  = .done
        }

        let order = Order()
        let cborOrder = try! CodableCBOREncoder().encode(order)
        let decodedCBOROrder = try! CodableCBORDecoder().decode(Order.self, from: cborOrder)

        XCTAssertEqual(decodedCBOROrder.status, order.status)
    }

    func testStructWithArray() {
        struct StructWithArray: Codable, Equatable {
            let arr: [Int]
        }

        let arraysToTest = [[], [1], [2, 3]]

        for arr in arraysToTest {
            let structWithArray = StructWithArray(arr: arr)

            let encoded = try! CodableCBOREncoder().encode(structWithArray)
            let decoded = try! CodableCBORDecoder().decode(StructWithArray.self, from: encoded)

            XCTAssertEqual(structWithArray, decoded)
        }
    }

    func testMultiTypeStruct() {
        struct MultiTypeStruct: Codable, Equatable {
            let stringVal: String
            let bytesVal: Data
            let integer: Int
            let booleanVal: Bool
            let doubleVal: Double
            let arrayVal: [Int]?
        }

        let arraysToTest: [[Int]?] = [[], nil]

        for arr in arraysToTest {
            let multiTypeStruct = MultiTypeStruct(
                stringVal: "s",
                bytesVal: Data(hex: "aabbcc")!,
                integer: 4711,
                booleanVal: true,
                doubleVal: 3.14,
                arrayVal: arr
            )

            let encoded = try! CodableCBOREncoder().encode(multiTypeStruct)
            let decoded = try! CodableCBORDecoder().decode(MultiTypeStruct.self, from: encoded)

            XCTAssertEqual(multiTypeStruct, decoded)
        }

        let hexToRoundtrip = [
            // Definite map without an arrayVal key-value pair
            "a56a626f6f6c65616e56616cf569737472696e6756616c63666f6f69646f75626c6556616cfb40091eb851eb851f67696e746567657219126768627974657356616c43aabbcc",

            // Indefinite map without an arrayVal key-value pair
            "bf6a626f6f6c65616e56616cf569737472696e6756616c63666f6f69646f75626c6556616cfb40091eb851eb851f67696e746567657219126768627974657356616c43aabbccff",

            // Definite map with an arrayVal key-value pair
            "a669737472696e6756616c63666f6f6a626f6f6c65616e56616cf567696e746567657219126769646f75626c6556616cfb40091eb851eb851f68627974657356616c43aabbcc68617272617956616c84010222191267",

            // Indefinite map with an arrayVal key-value pair
            "bf69737472696e6756616c63666f6f6a626f6f6c65616e56616cf567696e746567657219126769646f75626c6556616cfb40091eb851eb851f68627974657356616c43aabbcc68617272617956616c84010222191267ff"
        ]

        for hex in hexToRoundtrip {
            let _ = try! CodableCBORDecoder().decode(MultiTypeStruct.self, from: Data(hex: hex)!)
        }
    }

    func testAnyRecursive() {
        let anyRecursive: AnyRecursive = .object([
            "intValue": .number(10),
            "floatValue": .number(130.1),
            "stringValue": .string("name 1"),
            "boolValue": .bool(true),
            "nilValue": .null,
            "arrayValue": .array([.number(1000), .number(2000), .number(3000)]),
            "objectValue": .object(["intValue": .number(5100)])
        ])

        let encoded = try! CodableCBOREncoder().encode(anyRecursive)
        let decoded = try! CodableCBORDecoder().decode(AnyRecursive.self, from: encoded)
        XCTAssertEqual(anyRecursive, decoded)
    }

    func testOptionalArray() {
        struct StructWithOptionalArray: Codable, Equatable {
            var array: [InnerStruct]?
        }

        struct InnerStruct: Codable, Equatable {
            var parameter: String
        }

        let test1 = StructWithOptionalArray(array: [InnerStruct(parameter: "present")])
        let test2 = StructWithOptionalArray(array: nil)

        for testVal in [test1, test2] {
            let encoded = try! CodableCBOREncoder().encode(testVal)
            let decoded = try! CodableCBORDecoder().decode(StructWithOptionalArray.self, from: encoded)
            XCTAssertEqual(testVal, decoded)
        }
    }

    func testFoundationHeavyType() {
        struct FoundationLaden: Codable, Equatable {
            let date: Date
            let oldDate: Date
            let dateComponents: DateComponents
            let calendar: Calendar
            let locale: Locale
            let url: URL
            let urlComponents: URLComponents
            let measurement: Measurement<UnitMass>
            let uuid: UUID
            let personNameComponents: PersonNameComponents
            let timeZone: TimeZone
            let decimal: Decimal
            let dateInterval: DateInterval
            let characterSet: CharacterSet
            let indexPath: IndexPath
            let indexSet: IndexSet
            let range: Range<Int>
            let data: Data
        }

        var personNameComponents = PersonNameComponents()
        personNameComponents.givenName = "Bridget"
        personNameComponents.familyName = "Christie"
        personNameComponents.middleName = "Louise"
        personNameComponents.namePrefix = "Dame"
        personNameComponents.nickname = "Bridge"
        personNameComponents.nameSuffix = "Esq."

        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!
        let dateComponents: Set<Calendar.Component> = [
            .era,
            .year,
            .month,
            .day,
            .hour,
            .minute,
            .second,
            .weekday,
            .weekdayOrdinal,
            .weekOfMonth,
            .weekOfYear,
            .yearForWeekOfYear,
            .timeZone,
            .calendar,
            .nanosecond,
            .quarter,
        ]

        let foundationLadenObj = FoundationLaden(
            date: Date(timeIntervalSince1970: 1501283774),
            oldDate: Date(timeIntervalSince1970: -65672354),
            dateComponents: calendar.dateComponents(dateComponents, from: Date(timeIntervalSince1970: 1501283775)),
            calendar: calendar,
            locale: Locale(identifier: "UTC"),
            url: URL(string: "https://www.cars.com/cool/big?color=yellow")!,
            urlComponents: URLComponents(string: "https://subdomain.domain.com/some/path?and_a_query=string")!,
            measurement: Measurement(value: 67.4, unit: UnitMass.grams),
            uuid: UUID(),
            personNameComponents: personNameComponents,
            timeZone: TimeZone(identifier: "PST")!,
            decimal: Decimal(sign: .plus, exponent: -10, significand: 31415926536),
            dateInterval: DateInterval(start: Date(timeIntervalSince1970: 1501283772), duration: 86400),
            characterSet: CharacterSet.illegalCharacters,
            indexPath: IndexPath(indexes: [12, 3]),
            indexSet: IndexSet(arrayLiteral: 1, 2, 3, 9, 123, 1247890123),
            range: Range(NSRange(location: 12, length: 366))!,
            data: Data([163, 99, 95, 105, 100, 99, 97, 97, 97, 104, 99, 97, 116, 101, 103, 111, 114, 121, 100, 99, 97, 107, 101, 103, 111, 114, 100, 105, 110, 97, 108, 250, 65, 64, 0, 0])
        )

        let encoder = CodableCBOREncoder()
        encoder.useStringKeys = true
        let encodedWithStringKeys = try! encoder.encode(foundationLadenObj)
        let decoder = CodableCBORDecoder()
        decoder.useStringKeys = true
        let decodedFromStringKeys = try! decoder.decode(FoundationLaden.self, from: encodedWithStringKeys)
        XCTAssertEqual(decodedFromStringKeys, foundationLadenObj)

        encoder.dateStrategy = .annotatedMap
        let encodedWithStringKeysAndAnnotatedMapDate = try! encoder.encode(foundationLadenObj)
        decoder.dateStrategy = .annotatedMap
        let decodedFromStringKeysAndAnnotatedMapDate = try! decoder.decode(FoundationLaden.self, from: encodedWithStringKeysAndAnnotatedMapDate)
        XCTAssertEqual(decodedFromStringKeysAndAnnotatedMapDate, foundationLadenObj)

        XCTAssertNotEqual(encodedWithStringKeys, encodedWithStringKeysAndAnnotatedMapDate)

        let encoded = try! CodableCBOREncoder().encode(foundationLadenObj)
        let decoded = try! CodableCBORDecoder().decode(FoundationLaden.self, from: encoded)
        XCTAssertEqual(decoded, foundationLadenObj)

        XCTAssertNotEqual(encoded, encodedWithStringKeys)
        XCTAssertNotEqual(encoded, encodedWithStringKeysAndAnnotatedMapDate)
    }

#if os(macOS)
    func testMacOSOnlyTypes() {
        struct MacOSOnlyTypes: Codable, Equatable {
            let affineTransform: AffineTransform
            let point: NSPoint
            let size: NSSize
        }

        let macOSOnlyObj = MacOSOnlyTypes(
            affineTransform: AffineTransform(translationByX: 12.34, byY: -56.78),
            point: NSPoint(x: -99.123, y: 2.04),
            size: NSSize(width: 77.77, height: 88.88)
        )

        let encoder = CodableCBOREncoder()
        encoder.useStringKeys = true
        let encodedWithStringKeys = try! encoder.encode(macOSOnlyObj)
        let decoder = CodableCBORDecoder()
        decoder.useStringKeys = true
        let decodedFromStringKeys = try! decoder.decode(MacOSOnlyTypes.self, from: encodedWithStringKeys)
        XCTAssertEqual(decodedFromStringKeys, macOSOnlyObj)

        let encoded = try! CodableCBOREncoder().encode(macOSOnlyObj)
        let decoded = try! CodableCBORDecoder().decode(MacOSOnlyTypes.self, from: encoded)
        XCTAssertEqual(decoded, macOSOnlyObj)
    }
#endif
}

enum AnyRecursive: Equatable {
    case string(String)
    case number(Float)
    case object([String: AnyRecursive])
    case array([AnyRecursive])
    case bool(Bool)
    case null
}

extension AnyRecursive: Codable {
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()

        if let object = try? container.decode([String: AnyRecursive].self) {
            self = .object(object)
        } else if let array = try? container.decode([AnyRecursive].self) {
            self = .array(array)
        } else if let string = try? container.decode(String.self) {
            self = .string(string)
        } else if let bool = try? container.decode(Bool.self) {
            self = .bool(bool)
        } else if let number = try? container.decode(Float.self) {
            self = .number(number)
        } else if container.decodeNil() {
            self = .null
        } else {
            throw DecodingError.dataCorrupted(
                .init(
                    codingPath: decoder.codingPath,
                    debugDescription: "Invalid \(String(describing: AnyRecursive.self)) value."
                )
            )
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()

        switch self {
        case let .array(array):
            try container.encode(array)
        case let .object(object):
            try container.encode(object)
        case let .string(string):
            try container.encode(string)
        case let .number(number):
            try container.encode(number)
        case let .bool(bool):
            try container.encode(bool)
        case .null:
            try container.encodeNil()
        }
    }
}
