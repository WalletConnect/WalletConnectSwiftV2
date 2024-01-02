import Foundation
import XCTest
@testable import WalletConnectVerify


class VerifyContextFactoryTests: XCTestCase {
        var factory: VerifyContextFactory!

        override func setUp() {
            super.setUp()
            factory = VerifyContextFactory()
        }

        override func tearDown() {
            factory = nil
            super.tearDown()
        }

        func testScamValidation() {
            let context = factory.createVerifyContext(origin: "http://example.com", domain: "http://example.com", isScam: true)
            XCTAssertEqual(context.validation, .scam)
        }

        func testValidOriginAndDomain() {
            let context = factory.createVerifyContext(origin: "http://example.com", domain: "http://example.com", isScam: false)
            XCTAssertEqual(context.validation, .valid)
        }

        func testInvalidOriginAndDomain() {
            let context = factory.createVerifyContext(origin: "http://example.com", domain: "http://different.com", isScam: false)
            XCTAssertEqual(context.validation, .invalid)
        }

        func testUnknownValidation() {
            let context = factory.createVerifyContext(origin: nil, domain: "http://example.com", isScam: false)
            XCTAssertEqual(context.validation, .unknown)
        }
    }
