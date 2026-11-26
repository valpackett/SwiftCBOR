#if canImport(Testing) && canImport(PropertyBased)
import PropertyBased
import Testing

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
    static let edgeCases: [CBOR] = [
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
    ]

    static let halfCases: [Float] = [0, -1, 1, 12.5, .infinity, -.infinity]

    static func bytes(using rng: inout any SeededRandomNumberGenerator) -> [UInt8] {
        return (0..<Int.random(in: 0...64, using: &rng)).map { _ in
            UInt8.random(in: .min ... .max, using: &rng)
        }
    }

    static func string(using rng: inout any SeededRandomNumberGenerator) -> String {
        var result = ""
        let length = Int.random(in: 0...40, using: &rng)
        result.reserveCapacity(length)

        while result.unicodeScalars.count < length {
            let value = UInt32.random(in: 0...0x10FFFF, using: &rng)
            guard let scalar = Unicode.Scalar(value) else { continue }
            result.unicodeScalars.append(scalar)
        }

        return result
    }

    static func leaf(using rng: inout any SeededRandomNumberGenerator) -> CBOR {
        switch Int.random(in: 0..<10, using: &rng) {
        case 0:
            return edgeCases.randomElement(using: &rng)!
        case 1:
            let value = UInt64.random(in: .min ... .max, using: &rng)
            return .unsignedInt(value == 1 ? 2 : value)
        case 2:
            return .negativeInt(UInt64.random(in: .min ... .max, using: &rng))
        case 3:
            return .boolean(Bool.random(using: &rng))
        case 4:
            return .simple(UInt8.random(in: 32...255, using: &rng))
        case 5:
            return .utf8String(string(using: &rng))
        case 6:
            return .byteString(bytes(using: &rng))
        case 7:
            let value = Float(bitPattern: UInt32.random(in: .min ... .max, using: &rng))
            return .float(value.isNaN ? 0 : value)
        case 8:
            let value = Double(bitPattern: UInt64.random(in: .min ... .max, using: &rng))
            return .double(value.isNaN ? 0 : value)
        default:
            return .half(halfCases.randomElement(using: &rng)!)
        }
    }

    static func key(using rng: inout any SeededRandomNumberGenerator) -> CBOR {
        switch Int.random(in: 0..<6, using: &rng) {
        case 0:
            return .unsignedInt(UInt64.random(in: .min ... .max, using: &rng))
        case 1:
            return .negativeInt(UInt64.random(in: .min ... .max, using: &rng))
        case 2:
            return .utf8String(string(using: &rng))
        case 3:
            return .byteString(bytes(using: &rng))
        case 4:
            return .boolean(Bool.random(using: &rng))
        default:
            return .null
        }
    }

    static func value(depth: Int, using rng: inout any SeededRandomNumberGenerator) -> CBOR {
        if depth <= 0 {
            return leaf(using: &rng)
        }

        switch Int.random(in: 0..<4, using: &rng) {
        case 0:
            return leaf(using: &rng)
        case 1:
            let count = Int.random(in: 0...8, using: &rng)
            return .array((0..<count).map { _ in value(depth: depth - 1, using: &rng) })
        case 2:
            let count = Int.random(in: 0...6, using: &rng)
            var result: [CBOR: CBOR] = [:]
            for _ in 0..<count {
                result[key(using: &rng)] = value(depth: depth - 1, using: &rng)
            }
            return .map(result)
        default:
            let tag = UInt64.random(in: .min ... .max, using: &rng)
            return .tagged(.init(rawValue: tag == 1 ? 2 : tag), value(depth: depth - 1, using: &rng))
        }
    }
}

private let cborGenerator = Generator<CBOR, Shrink.None<CBOR>> { rng in
    CBORPropertyGenerator.value(depth: 3, using: &rng)
}

private let stringGenerator = Generator<String, Shrink.None<String>> { rng in
    CBORPropertyGenerator.string(using: &rng)
}

private let codableRecordGenerator = zip(
    Gen<Int>.int(),
    Gen<UInt16>.uint16(),
    stringGenerator,
    Gen<UInt8>.uint8().array(of: 0...64),
    Gen<Bool>.bool,
    stringGenerator.array(of: 0...8).optional
).map { input in
    CodablePropertyRecord(
        integer: input.0,
        unsigned: input.1,
        text: input.2,
        bytes: input.3,
        flag: input.4,
        nested: input.5
    )
}

@Test func arbitraryInputEitherDecodesOrThrowsATypedError() async {
    await propertyCheck(count: 500, input: Gen<UInt8>.uint8().array(of: 0...256)) { input in
        do {
            _ = try CBOR.decode(input)
        } catch {
            #expect(error is CBORError)
        }
    }
}

@Test func truncatedCBORInputIsHandledSafely() async {
    await propertyCheck(count: 500, input: cborGenerator, Gen<UInt64>.uint64()) { value, cutPoint in
        let bytes = value.encode()
        let length = Int(cutPoint % UInt64(bytes.count + 1))

        do {
            _ = try CBOR.decode(Array(bytes.prefix(length)))
        } catch {
            #expect(error is CBORError)
        }
    }
}

@Test func generatedFixedWidthCBORRoundTrips() async {
    let options = CBOROptions(useShortestFloatEncoding: false)

    await propertyCheck(count: 500, input: cborGenerator) { value in
        let decoded = try CBOR.decode(value.encode(options: options))
        #expect(decoded == value)
    }
}

@Test func generatedPreferredCBORRereencodesIdentically() async {
    await propertyCheck(count: 500, input: cborGenerator) { value in
        let encoded = value.encode()
        let decoded = try #require(try CBOR.decode(encoded))

        #expect(decoded.encode() == encoded)
    }
}

@Test func generatedCBOREncoderPathsAgree() async {
    await propertyCheck(count: 500, input: cborGenerator) { value in
        var output: [UInt8] = []
        value.encode(into: &output)

        #expect(output == value.encode())
        #expect(output == CBOR.encode(value))
    }
}

@Test func generatedCodableRecordsRoundTrip() async {
    await propertyCheck(count: 500, input: codableRecordGenerator) { record in
        let data = try CodableCBOREncoder().encode(record)
        let decoded = try CodableCBORDecoder().decode(CodablePropertyRecord.self, from: data)
        #expect(decoded == record)
    }
}
#endif
