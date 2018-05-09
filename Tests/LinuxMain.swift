import XCTest
@testable import SwiftCBORTests

XCTMain([
    testCase(CBORDecoderTests.allTests),
    testCase(CBOREncoderTests.allTests),
])
