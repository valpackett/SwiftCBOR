import XCTest
import Foundation
@testable import SwiftCBOR

class CBORDateTests: XCTestCase {
    
    struct CustomAndBool: Decodable {
        let date: CustomDataDecodable
        let bool: Bool
        
        enum CodingKeys: Int, CodingKey {
            case date = 0
            case bool = 3
        }
    }
    
    struct DateAndBool: Codable {
        let date: Date
        let bool: Bool
        
        enum CodingKeys: Int, CodingKey {
            case date = 0
            case bool = 3
        }
    }
    
    struct BoolOnly: Codable {
        let bool: Bool
        
        enum CodingKeys: Int, CodingKey {
            case bool = 3
        }
    }
    
    func testDecodeDate_C1_and_Date() {
        let testData = Data(hex: "A2 00C11A682C4A77 03F5"
            .replacingOccurrences(of: " ", with: ""))!
        let decodedStruct = try! CodableCBORDecoder().decode(DateAndBool.self, from: testData)
        XCTAssertNotNil(decodedStruct)
    }
    
    func testDecodeDate_C0_noFatalError() {
        let testData = Data(hex: "A4 00C01A682C4A77 01C01A682C4A77 02C01A682C4A77 03F5"
            .replacingOccurrences(of: " ", with: ""))!
        do {
            let _ = try CodableCBORDecoder().decode(DateAndBool.self, from: testData)
            XCTFail("Must throw an error instead of fatalError")
        } catch {
            XCTAssertNotNil(error)
        }
    }
    
    func testDecodeDate_C0_and_bool_noFatalErrorForPartialModel() {
        let testData = Data(hex: "A4 00C01A682C4A77 01C01A682C4A77 02C01A682C4A77 03F5"
            .replacingOccurrences(of: " ", with: ""))!
        let decodedStruct = try? CodableCBORDecoder().decode(BoolOnly.self, from: testData)
        XCTAssertNotNil(decodedStruct)
    }
    
    func testDecodeDate_C0_custom_epoch() {
        //
        let testData = Data(hex: "A4 00C01A682C4A7701C 01A682C4A77 02C01A682C4A77 03F5"
            .replacingOccurrences(of: " ", with: ""))!
        let decodedStruct = try? CodableCBORDecoder().decode(CustomAndBool.self, from: testData)
        XCTAssertNotNil(decodedStruct?.date)
        XCTAssertNotNil(decodedStruct)
        XCTAssertNotNil(decodedStruct?.date.date)
    }
    
    func testDecodeDate_C0_custom_string() {
        for formatter in [CustomDataDecodable.dateTimeWithMillisFormatter, CustomDataDecodable.dateTimeFormatter, CustomDataDecodable.onlyDateFormatter] {
            let isoDate = formatter.string(from: Date())
            let cbor = CBOR.tagged(CBOR.Tag.standardDateTimeString, .utf8String(isoDate))
            let c0DateString = Data(cbor.encode()).hex
            
            let testData = Data(hex: "A2 00 \(c0DateString) 03F5"
                .replacingOccurrences(of: " ", with: ""))!
            
            let decodedStruct = try? CodableCBORDecoder().decode(CustomAndBool.self, from: testData)
            XCTAssertNotNil(decodedStruct?.date.date)
            
            // just check that no any fatal error
            let wrongDecodedStruct = try? CodableCBORDecoder().decode(DateAndBool.self, from: testData)
            XCTAssertNil(wrongDecodedStruct)
        }
    }
}

/// it decodes C0 and C1 dates
struct CustomDataDecodable: Decodable {
    let date: Date
    init(from decoder: Decoder) throws {
        let container = (try decoder.singleValueContainer()) as? CBORDecodingContainer
        guard let arrayData = container?.data else {
            throw DecodingError.dataCorrupted(DecodingError.Context(codingPath: [], debugDescription: "can't cast to `CBORDecodingContainer`"))
        }
        self.date = try Self.dateFromCBORData(Data(arrayData))
    }
    
    static func dateFromCBORData(_ data: Data) throws -> Date {
        let c0 = 0xC0 + CBOR.Tag.standardDateTimeString.rawValue
        let c1 = 0xC0 + CBOR.Tag.epochBasedDateTime.rawValue
        if data.count > 1, data[0] == c0 || data[0] == c1 { // 0xC0 or 0xC1
            let timeData = data.suffix(from: 1)
            let item = try CBOR.decode([UInt8](timeData))
            
            if let item {
                if let date = try? getDateFromTimestamp(item) {
                    return date
                } else if case .utf8String(let string) = item {
                    for formatter in [Self.dateTimeWithMillisFormatter, Self.dateTimeFormatter, Self.onlyDateFormatter] {
                        if let date = formatter.date(from: string) {
                            return date
                        }
                    }
                }
            }
        }
        throw DecodingError.dataCorrupted(DecodingError.Context(codingPath: [], debugDescription: "CBOR Data to Date decode failed"))
    }
}

extension CustomDataDecodable {
    
    // 2017-01-23T10:12:31.484Z
    static let dateTimeWithMillisFormatter: ISO8601DateFormatter = {
        let v = ISO8601DateFormatter()
        v.timeZone = TimeZone(identifier: "UTC")
        v.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return v
    }()
    
    // 2021-06-30T19:22:31Z
    static let dateTimeFormatter: ISO8601DateFormatter = {
        let v = ISO8601DateFormatter()
        v.timeZone = TimeZone(identifier: "UTC")
        v.formatOptions = [.withInternetDateTime]
        return v
    }()
    
    // 2016-06-13
    static let onlyDateFormatter: ISO8601DateFormatter = {
        let v = ISO8601DateFormatter()
        v.timeZone = TimeZone(identifier: "UTC")
        v.formatOptions = .withFullDate
        return v
    }()
}
