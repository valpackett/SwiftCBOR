import XCTest
@testable import SwiftCBOR

class CodableCBORDecoderTests: XCTestCase {
    func testDecodeNull() {
        let decoded = try! CodableCBORDecoder().decode(Optional<String>.self, from: Data([0xf6]))
        XCTAssertNil(decoded)
    }

    func testDecodeBools() {
        let falseVal = try! CodableCBORDecoder().decode(Bool.self, from: Data([0xf4]))
        XCTAssertEqual(falseVal, false)
        let trueVal = try! CodableCBORDecoder().decode(Bool.self, from: Data([0xf5]))
        XCTAssertEqual(trueVal, true)
    }

    func testDecodeInts() {
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

    func testDecodeNegativeInts() {
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

    func testDecodeStrings() {
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

    func testDecodeByteStrings() {
        let fourByteByteString = try! CodableCBORDecoder().decode(Data.self, from: Data([0x44, 0x01, 0x02, 0x03, 0x04]))
        XCTAssertEqual(fourByteByteString, Data([0x01, 0x02, 0x03, 0x04]))
        let indefiniteByteSting = try! CodableCBORDecoder().decode(Data.self, from: Data([0x5f, 0x42, 0x01, 0x02, 0x43, 0x03, 0x04, 0x05, 0xff]))
        XCTAssertEqual(indefiniteByteSting, Data([0x01, 0x02, 0x03, 0x04, 0x05]))
    }

    func testDecodeArrays() {
        let empty = try! CodableCBORDecoder().decode([String].self, from: Data([0x80]))
        XCTAssertEqual(empty, [])
        let oneTwoThree = try! CodableCBORDecoder().decode([Int].self, from: Data([0x83, 0x01, 0x02, 0x03]))
        XCTAssertEqual(oneTwoThree, [1, 2, 3])
        let lotsOfInts = try! CodableCBORDecoder().decode([Int].self, from: Data([0x98, 0x19, 0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08, 0x09, 0x0a, 0x0b, 0x0c, 0x0d, 0x0e, 0x0f, 0x10, 0x11, 0x12, 0x13, 0x14, 0x15, 0x16, 0x17, 0x18, 0x18, 0x18, 0x19]))
        XCTAssertEqual(lotsOfInts, [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25])
        let nestedSimple = try! CodableCBORDecoder().decode([[Int]].self, from: Data([0x83, 0x81, 0x01, 0x82, 0x02, 0x03, 0x82, 0x04, 0x05]))
        XCTAssertEqual(nestedSimple, [[1], [2, 3], [4, 5]])
        let indefiniteArray = try! CodableCBORDecoder().decode([Int].self, from: Data([0x9f, 0x04, 0x05, 0xff]))
        XCTAssertEqual(indefiniteArray, [4, 5])
        let nestedIndefiniteArrays = try! CodableCBORDecoder().decode([[Int]].self, from: Data([0x9f, 0x81, 0x01, 0x82, 0x02, 0x03, 0x9f, 0x04, 0x05, 0xff, 0xff]))
        XCTAssertEqual(nestedIndefiniteArrays, [[1], [2, 3], [4, 5]])
    }

    func testDecodeMaps() {
        let empty = try! CodableCBORDecoder().decode([String: String].self, from: Data([0xa0]))
        XCTAssertEqual(empty, [:])
        let stringToString = try! CodableCBORDecoder().decode([String: String].self, from: Data([0xa5, 0x61, 0x61, 0x61, 0x41, 0x61, 0x62, 0x61, 0x42, 0x61, 0x63, 0x61, 0x43, 0x61, 0x64, 0x61, 0x44, 0x61, 0x65, 0x61, 0x45]))
        XCTAssertEqual(stringToString, ["a": "A", "b": "B", "c": "C", "d": "D", "e": "E"])
        let oneTwoThreeFour = try! CodableCBORDecoder().decode([Int: Int].self, from: Data([0xa2, 0x01, 0x02, 0x03, 0x04]))
        XCTAssertEqual(oneTwoThreeFour, [1: 2, 3: 4])
        let indefiniteMap = try! CodableCBORDecoder().decode([String: String].self, from: Data([0xbf, 0x63, 0x46, 0x75, 0x6e, 0x61, 0x62, 0x63, 0x41, 0x6d, 0x74, 0x61, 0x63, 0xff]))
        XCTAssertEqual(indefiniteMap, ["Fun": "b", "Amt": "c"])
        let nestedIndefiniteMap = try! CodableCBORDecoder().decode([String: [String: String]].self, from: Data([0xbf, 0x63, 0x46, 0x75, 0x6e, 0xa1, 0x61, 0x62, 0x61, 0x42, 0x63, 0x41, 0x6d, 0x74, 0xbf, 0x61, 0x63, 0x61, 0x43, 0xff, 0xff]))
        XCTAssertEqual(nestedIndefiniteMap, ["Fun": ["b": "B"], "Amt": ["c": "C"]])
    }

    func testDecodeDates() {
        let expectedDateOne = Date(timeIntervalSince1970: 1363896240)
        let dateOne = try! CodableCBORDecoder().decode(Date.self, from: Data([0xc1, 0x1a, 0x51, 0x4b, 0x67, 0xb0]))
        XCTAssertEqual(dateOne, expectedDateOne)
        let expectedDateTwo = Date(timeIntervalSince1970: 1363896240.5)
        let dateTwo = try! CodableCBORDecoder().decode(Date.self, from: Data([0xc1, 0xfb, 0x41, 0xd4, 0x52, 0xd9, 0xec, 0x20, 0x00, 0x00]))
        XCTAssertEqual(dateTwo, expectedDateTwo)
    }

    /// Test that maximumDepth option is properly accessible and passed through
    func testMaximumDepthOptionAccessible() throws {
        // Test that maximumDepth is accessible and can be set
        let decoder = CodableCBORDecoder()
        XCTAssertEqual(decoder.maximumDepth, .max) // Default value

        decoder.maximumDepth = 100
        XCTAssertEqual(decoder.maximumDepth, 100)

        // Test that options are properly converted
        let options = decoder.options
        XCTAssertEqual(options.maximumDepth, 100)

        let cborOptions = options.toCBOROptions()
        XCTAssertEqual(cborOptions.maximumDepth, 100)

        XCTAssertEqual(decoder.options.maximumDepth, decoder.maximumDepth)
    }

    /// Test that depth is enforced across nested array structures
    func testMaximumDepthEnforcedAcrossNestedArrays() throws {
        // Create a deeply nested array: [[[[42]]]] (4 levels deep)
        // Level 0: outer array
        // Level 1: first nested array
        // Level 2: second nested array
        // Level 3: third nested array
        // Level 4: innermost value (42)
        let deeplyNested = try! CodableCBOREncoder().encode([[[[42]]]])

        // Should succeed with depth limit of 5 or more
        let decoder5 = CodableCBORDecoder()
        decoder5.maximumDepth = 5
        XCTAssertNoThrow(try decoder5.decode([[[[Int]]]].self, from: deeplyNested))

        // Should fail with depth limit of 3 (can't reach level 4)
        let decoder3 = CodableCBORDecoder()
        decoder3.maximumDepth = 3
        XCTAssertThrowsError(try decoder3.decode([[[[Int]]]].self, from: deeplyNested)) { error in
            guard case DecodingError.dataCorrupted(let context) = error else {
                XCTFail("Expected dataCorrupted error, got \(error)")
                return
            }
            XCTAssertTrue(context.debugDescription.contains("Maximum decoding depth"))
        }

        // Should fail with depth limit of 0 (can't even decode top level)
        let decoder0 = CodableCBORDecoder()
        decoder0.maximumDepth = 0
        XCTAssertThrowsError(try decoder0.decode([[[[Int]]]].self, from: deeplyNested)) { error in
            guard case DecodingError.dataCorrupted(let context) = error else {
                XCTFail("Expected dataCorrupted error, got \(error)")
                return
            }
            XCTAssertTrue(context.debugDescription.contains("Maximum decoding depth"))
        }
    }

    /// Test that depth is enforced across nested map structures
    func testMaximumDepthEnforcedAcrossNestedMaps() throws {
        struct Level3: Codable, Equatable { let value: Int }
        struct Level2: Codable, Equatable { let nested: Level3 }
        struct Level1: Codable, Equatable { let nested: Level2 }
        struct Level0: Codable, Equatable { let nested: Level1 }

        let deeply = Level0(nested: Level1(nested: Level2(nested: Level3(value: 42))))
        let encoded = try! CodableCBOREncoder().encode(deeply)

        // Should succeed with sufficient depth
        let decoder5 = CodableCBORDecoder()
        decoder5.maximumDepth = 5
        XCTAssertNoThrow(try decoder5.decode(Level0.self, from: encoded))

        // Should fail with insufficient depth
        let decoder2 = CodableCBORDecoder()
        decoder2.maximumDepth = 2
        XCTAssertThrowsError(try decoder2.decode(Level0.self, from: encoded)) { error in
            guard case DecodingError.dataCorrupted(let context) = error else {
                XCTFail("Expected dataCorrupted error, got \(error)")
                return
            }
            XCTAssertTrue(context.debugDescription.contains("Maximum decoding depth"))
        }
    }

    /// Test that depth is enforced across mixed array and map structures
    func testMaximumDepthEnforcedAcrossMixedStructures() throws {
        struct Inner: Codable, Equatable { let values: [Int] }
        struct Outer: Codable, Equatable { let items: [Inner] }

        let mixed = Outer(items: [Inner(values: [1, 2]), Inner(values: [3, 4])])
        let encoded = try! CodableCBOREncoder().encode(mixed)

        // Structure depth:
        // Level 0: Outer keyed container
        // Level 1: items array
        // Level 2: Inner keyed container
        // Level 3: values array
        // Level 4: Int values

        // Should succeed with depth 5
        let decoder5 = CodableCBORDecoder()
        decoder5.maximumDepth = 5
        let decoded = try! decoder5.decode(Outer.self, from: encoded)
        XCTAssertEqual(decoded, mixed)

        // Should fail with depth 2 (can't reach Inner level)
        let decoder2 = CodableCBORDecoder()
        decoder2.maximumDepth = 2
        XCTAssertThrowsError(try decoder2.decode(Outer.self, from: encoded)) { error in
            guard case DecodingError.dataCorrupted(let context) = error else {
                XCTFail("Expected dataCorrupted error, got \(error)")
                return
            }
            XCTAssertTrue(context.debugDescription.contains("Maximum decoding depth"))
        }
    }

    /// Test the specific case from the bug report: 10-deep nested array with depth=5 should fail
    func testDeepNestedArrayRespectDepthLimit() throws {
        // Create 10-level deep nested array
        typealias Level10 = [[[[[[[[[[Int]]]]]]]]]]

        let level1: [Int] = [42]
        let level2: [[Int]] = [level1]
        let level3: [[[Int]]] = [level2]
        let level4: [[[[Int]]]] = [level3]
        let level5: [[[[[Int]]]]] = [level4]
        let level6: [[[[[[Int]]]]]] = [level5]
        let level7: [[[[[[[Int]]]]]]] = [level6]
        let level8: [[[[[[[[Int]]]]]]]] = [level7]
        let level9: [[[[[[[[[Int]]]]]]]]] = [level8]
        let level10: Level10 = [level9]

        let encoded = try! CodableCBOREncoder().encode(level10)

        // Should fail with depth limit of 5
        let decoder = CodableCBORDecoder()
        decoder.maximumDepth = 5

        XCTAssertThrowsError(try decoder.decode(Level10.self, from: encoded)) { error in
            guard case DecodingError.dataCorrupted(let context) = error else {
                XCTFail("Expected dataCorrupted error, got \(error)")
                return
            }
            XCTAssertTrue(context.debugDescription.contains("Maximum decoding depth"))
        }
    }

    /// Test that depth tracking works correctly when decoding array elements
    func testDepthTrackingInArrayElements() throws {
        // Array of arrays: [[1], [2], [3]]
        // Each inner array is at depth 1 when decoded as an element
        let arrayOfArrays = [[1], [2], [3]]
        let encoded = try! CodableCBOREncoder().encode(arrayOfArrays)

        // Should succeed with depth 3
        let decoder3 = CodableCBORDecoder()
        decoder3.maximumDepth = 3
        let decoded = try! decoder3.decode([[Int]].self, from: encoded)
        XCTAssertEqual(decoded, arrayOfArrays)

        // Should fail with depth 1 (can't decode inner arrays)
        let decoder1 = CodableCBORDecoder()
        decoder1.maximumDepth = 1
        XCTAssertThrowsError(try decoder1.decode([[Int]].self, from: encoded)) { error in
            guard case DecodingError.dataCorrupted(let context) = error else {
                XCTFail("Expected dataCorrupted error, got \(error)")
                return
            }
            XCTAssertTrue(context.debugDescription.contains("Maximum decoding depth"))
        }
    }
}
