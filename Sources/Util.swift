#if canImport(Foundation)
import Foundation
#endif

final class Util {
    // https://stackoverflow.com/questions/24465475/how-can-i-create-a-string-from-utf8-in-swift
    static func decodeUtf8(_ bytes: ArraySlice<UInt8>) throws -> String {
#if canImport(Foundation)
        guard let result = String(bytes: bytes, encoding: .utf8) else {
            throw CBORError.incorrectUTF8String
        }
        return result
#else
        var result = ""
        var decoder = UTF8()
        var generator = bytes.makeIterator()
        var finished = false
        repeat {
            let decodingResult = decoder.decode(&generator)
            switch decodingResult {
            case .scalarValue(let char):
                result.append(String(char))
            case .emptyInput:
                finished = true
            case .error:
                throw CBORError.incorrectUTF8String
            }
        } while (!finished)
        return result
#endif
    }

    static func djb2Hash<S: Sequence>(_ values: S) -> Int where S.Element == Int {
        values.reduce(5381, { hash, elem in ((hash << 5) &+ hash) &+ elem })
    }

    // https://gist.github.com/martinkallman/5049614
    // rewritten to Swift + applied fixes from comments + added NaN/Inf checks
    // The zero, subnormal, infinity and NaN cases follow RFC 8949 Appendix D.
    static func readFloat16(x: UInt16) -> Float32 {
        let exponent = (x >> 10) & 0x1f
        let mantissa = x & 0x03ff
        let sign: FloatingPointSign = (x & 0x8000) != 0 ? .minus : .plus

        if exponent == 0x1f {
            // Infinity or NaN.
            if mantissa == 0 {
                return sign == .minus ? -Float32.infinity : Float32.infinity
            }
            return Float32.nan
        }
        if exponent == 0 {
            // Zero or subnormal: the value is the mantissa multiplied by 2^-24.
            return Float32(sign: sign, exponent: -24, significand: Float32(mantissa))
        }
        var t1 = UInt32(x & 0x7fff)        // Non-sign bits
        var t2 = UInt32(x & 0x8000)        // Sign bit
        t1 <<= 13                          // Align mantissa on MSB
        t2 <<= 16                          // Shift sign bit into position
        t1 += 0x38000000                   // Adjust bias
        t1 |= t2                           // Re-insert sign bit
        return Float32(bitPattern: t1)
    }
}
