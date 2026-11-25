import SwiftCheck
import XCTest

@testable import SwiftCBOR

private struct CodablePropertyRecord: Codable, Equatable {
    let integer: Int
    let unsigned: UInt16
    let text: String
    let bytes: [UInt8]
    let flag: Bool
    let nested: [String]?
}

private enum CBORPropertyGenerator {
    static let leaf = Gen<CBOR>.one(of: [
        Gen<CBOR>.fromElements(of: [
            .unsignedInt(0), .unsignedInt(23), .unsignedInt(24),
            .unsignedInt(255), .unsignedInt(256), .unsignedInt(65_535),
            .unsignedInt(65_536), .unsignedInt(4_294_967_295),
            .unsignedInt(4_294_967_296), .unsignedInt(UInt64.max),
            .negativeInt(0), .negativeInt(23), .negativeInt(24),
            .negativeInt(255), .negativeInt(UInt64.max),
            .boolean(true), .boolean(false), .null, .undefined,
            .simple(32), .simple(255),
            .half(0), .half(-1), .half(1), .half(12.5),
            .half(.infinity), .half(-.infinity),
            .float(0), .float(-1), .float(1), .float(.infinity),
            .double(0), .double(-1), .double(1), .double(.infinity),
        ]),
        UInt64.arbitrary
            .map { $0 == 1 ? 2 : $0 }
            .map(CBOR.unsignedInt),
        UInt64.arbitrary.map(CBOR.negativeInt),
        Bool.arbitrary.map(CBOR.boolean),
        UInt8.arbitrary
            .map { UInt8(32 + (UInt32($0) % 224)) }
            .map(CBOR.simple),
        String.arbitrary.map(CBOR.utf8String),
        [UInt8].arbitrary.map(CBOR.byteString),
        Float.arbitrary
            .map { $0.isNaN ? 0 : $0 }
            .map(CBOR.float),
        Double.arbitrary
            .map { $0.isNaN ? 0 : $0 }
            .map(CBOR.double),
    ])

    static let key = Gen<CBOR>.one(of: [
        UInt64.arbitrary.map(CBOR.unsignedInt),
        UInt64.arbitrary.map(CBOR.negativeInt),
        String.arbitrary.map(CBOR.utf8String),
        [UInt8].arbitrary.map(CBOR.byteString),
        Bool.arbitrary.map(CBOR.boolean),
        Gen<CBOR>.pure(.null),
    ])

    static func value(_ depth: Int) -> Gen<CBOR> {
        if depth <= 0 {
            return leaf
        }

        return Gen<CBOR>.one(of: [
            leaf,
            array(depth - 1),
            map(depth - 1),
            tagged(depth - 1),
        ])
    }

    static func array(_ depth: Int) -> Gen<CBOR> {
        return Gen<CBOR>.sized { size in
            let count = Gen<Int>.choose((0, min(size, 8)))
            return count.flatMap { length in
                value(depth).proliferate(withSize: length).map(CBOR.array)
            }
        }
    }

    static func map(_ depth: Int) -> Gen<CBOR> {
        return Gen<CBOR>.sized { size in
            let count = Gen<Int>.choose((0, min(size, 6)))
            return count.flatMap { length in
                let keys = key.proliferate(withSize: length)
                let values = value(depth).proliferate(withSize: length)
                return Gen<([CBOR], [CBOR])>.zip(keys, values).map { keys, values in
                    let pairs = zip(keys, values)
                    return CBOR.map(Dictionary(pairs, uniquingKeysWith: { _, last in last }))
                }
            }
        }
    }

    static func tagged(_ depth: Int) -> Gen<CBOR> {
        return Gen<(UInt64, CBOR)>.zip(
            UInt64.arbitrary.map { $0 == 1 ? 2 : $0 },
            value(depth)
        ).map { CBOR.tagged(.init(rawValue: $0), $1) }
    }
}

private var cborGenerator: Gen<CBOR> {
    return Gen.sized { size in
        CBORPropertyGenerator.value(min(3, size / 25))
    }
}

final class CBORPropertyTests: XCTestCase {
    func testArbitraryInputEitherDecodesOrThrowsATypedError() {
        property("Arbitrary byte input is handled safely") <- forAll { (input: [UInt8]) in
            do {
                _ = try CBOR.decode(input)
                return true
            } catch {
                return error is CBORError
            }
        }
    }

    func testTruncatedCBORInputIsHandledSafely() {
        property("Every prefix of encoded CBOR is handled safely") <- forAllNoShrink(
            cborGenerator,
            UInt64.arbitrary
        ) { value, cutPoint in
            let bytes = value.encode()
            let length = Int(truncatingIfNeeded: cutPoint) % (bytes.count + 1)

            do {
                _ = try CBOR.decode(Array(bytes.prefix(length)))
                return true
            } catch {
                return error is CBORError
            }
        }
    }

    func testGeneratedCBORRoundTrips() {
        property("Generated CBOR values round-trip byte for value") <- forAllNoShrink(cborGenerator) { value in
            guard let decoded = try CBOR.decode(value.encode()) else {
                return false
            }

            return decoded == value
        }
    }

    func testGeneratedCBOREncoderPathsAgree() {
        property("All supported general encoder paths produce the same bytes") <- forAllNoShrink(cborGenerator) { value in
            var output: [UInt8] = []
            value.encode(into: &output)

            return output == value.encode()
                && output == CBOR.encode(value)
        }
    }

    func testGeneratedCodableRecordsRoundTrip() {
        property("Generated Codable records round-trip") <- forAll {
            (
                integer: Int,
                unsigned: UInt16,
                text: String,
                bytes: [UInt8],
                flag: Bool,
                nested: [String]?
            ) in
            let record = CodablePropertyRecord(
                integer: integer,
                unsigned: unsigned,
                text: text,
                bytes: bytes,
                flag: flag,
                nested: nested
            )

            do {
                let data = try CodableCBOREncoder().encode(record)
                let decoded = try CodableCBORDecoder().decode(
                    CodablePropertyRecord.self,
                    from: data
                )
                return decoded == record
            } catch {
                return false
            }
        }
    }
}
