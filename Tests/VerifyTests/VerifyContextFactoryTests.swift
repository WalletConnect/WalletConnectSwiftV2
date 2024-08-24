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
        let context = factory.createVerifyContext(origin: "http://example.com", domain: "http://example.com", isScam: true, isVerified: nil)
        XCTAssertEqual(context.validation, .scam)
    }

    func testValidOriginAndDomain() {
        let context = factory.createVerifyContext(origin: "http://example.com", domain: "http://example.com", isScam: false, isVerified: nil)
        XCTAssertEqual(context.validation, .valid)
    }

    func testInvalidOriginAndDomain() {
        let context = factory.createVerifyContext(origin: "http://example.com", domain: "http://different.com", isScam: false, isVerified: nil)
        XCTAssertEqual(context.validation, .invalid)
    }

    func testUnknownValidation() {
        let context = factory.createVerifyContext(origin: nil, domain: "http://example.com", isScam: false, isVerified: nil)
        XCTAssertEqual(context.validation, .unknown)
    }

    func testVerifyContextIsMarkedAsUnknownWhenIsVerifiedIsFalse() {
        let context = factory.createVerifyContext(origin: "http://example.com", domain: "http://example.com", isScam: false, isVerified: false)
        XCTAssertEqual(context.validation, .unknown)
    }

    func testVerifyContextIsMarkedAsScamWhenIsScamIsTrueRegardlessOfIsVerified() {
        let context = factory.createVerifyContext(origin: "http://example.com", domain: "http://example.com", isScam: true, isVerified: true)
        XCTAssertEqual(context.validation, .scam)

        let contextWithFalseVerification = factory.createVerifyContext(origin: "http://example.com", domain: "http://example.com", isScam: true, isVerified: false)
        XCTAssertEqual(contextWithFalseVerification.validation, .scam)
    }

    func testValidOriginAndDomainWithoutScheme() {
        let context = factory.createVerifyContext(origin: "https://dev.lab.web3modal.com", domain: "dev.lab.web3modal.com", isScam: false, isVerified: nil)
        XCTAssertEqual(context.validation, .valid)
    }

    func testInvalidOriginAndDomainWithoutScheme() {
        let context = factory.createVerifyContext(origin: "https://dev.lab.web3modal.com", domain: "different.com", isScam: false, isVerified: nil)
        XCTAssertEqual(context.validation, .invalid)
    }

    // tests for createVerifyContextForLinkMode

    func testValidUniversalLink() {
        let context = factory.createVerifyContextForLinkMode(redirectUniversalLink: "https://www.example.com/universallink", domain: "https://example.com")
        XCTAssertEqual(context.validation, .valid)
    }

    func testInvalidUniversalLink() {
        let context = factory.createVerifyContextForLinkMode(redirectUniversalLink: "https://www.invalid.com/universallink", domain: "https://example.com")
        XCTAssertEqual(context.validation, .invalid)
    }

    func testInvalidUniversalLinkFormat() {
        let context = factory.createVerifyContextForLinkMode(redirectUniversalLink: "invalidurl", domain: "https://example.com")
        XCTAssertEqual(context.validation, .invalid)
    }

    func testInvalidDomainFormat() {
        let context = factory.createVerifyContextForLinkMode(redirectUniversalLink: "https://www.example.com/universallink", domain: "invalidurl")
        XCTAssertEqual(context.validation, .invalid)
    }

    func testSubdomainMatch() {
        let context = factory.createVerifyContextForLinkMode(redirectUniversalLink: "https://sub.example.com/universallink", domain: "https://example.com")
        XCTAssertEqual(context.validation, .valid)
    }

    func testUppercaseDomainMatch() {
        let context = factory.createVerifyContextForLinkMode(redirectUniversalLink: "https://WWW.EXAMPLE.COM/universallink", domain: "https://example.com")
        XCTAssertEqual(context.validation, .valid)
    }

    func testEmptyHost() {
        let context = factory.createVerifyContextForLinkMode(redirectUniversalLink: "https://", domain: "https://example.com")
        XCTAssertEqual(context.validation, .invalid)
    }
}
