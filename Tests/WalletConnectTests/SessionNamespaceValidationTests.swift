import XCTest
@testable import WalletConnect

final class SessionNamespaceValidationTests: XCTestCase {
    
    let sampleAccount = Account("eip155:1:0xab16a96d359ec26a11e2c2b3d8f8b8942d5bfcdb")!
    let sampleAccount2 = Account("eip155:137:0xab16a96d359ec26a11e2c2b3d8f8b8942d5bfcdb")!
    
    func testValidNamespace() {
        let namespace = [
            "eip155": SessionNamespace(
                accounts: [sampleAccount],
                methods: ["method"],
                events: ["event"],
                extensions: [
                    SessionNamespace.Extension(accounts: [sampleAccount2], methods: ["otherMethod"], events: ["otherEvent"])
                ]
            )
        ]
        XCTAssertNoThrow(try Namespace.validate(namespace))
    }
    
    func testChainsMustNotNotBeEmpty() {
        let namespace = [
            "eip155": SessionNamespace(
                accounts: [],
                methods: ["method"],
                events: ["event"],
                extensions: nil)
        ]
        XCTAssertThrowsError(try Namespace.validate(namespace))
    }
    
    func testAllowsEmptyMethods() {
        let namespace = [
            "eip155": SessionNamespace(
                accounts: [sampleAccount],
                methods: [],
                events: ["event"],
                extensions: nil)
        ]
        XCTAssertNoThrow(try Namespace.validate(namespace))
    }
    
    func testAllowsEmptyEvents() {
        let namespace = [
            "eip155": SessionNamespace(
                accounts: [sampleAccount],
                methods: ["method"],
                events: [],
                extensions: nil)
        ]
        XCTAssertNoThrow(try Namespace.validate(namespace))
    }
    
    func testAllChainsContainsNamespacePrefix() {
        let validNamespace = [
            "eip155": SessionNamespace(
                accounts: [sampleAccount, sampleAccount2],
                methods: ["method"],
                events: ["event"],
                extensions: nil)
        ]
        let invalidNamespace = [
            "eip155": SessionNamespace(
                accounts: [sampleAccount, Account("cosmos:cosmoshub-4:cosmos1t2uflqwqe0fsj0shcfkrvpukewcw40yjj6hdc0")!],
                methods: ["method"],
                events: ["event"],
                extensions: nil)
        ]
        XCTAssertNoThrow(try Namespace.validate(validNamespace))
        XCTAssertThrowsError(try Namespace.validate(invalidNamespace))
    }
    
    func testExtensionChainsMustNotBeEmpty() {
        let namespace = [
            "eip155": SessionNamespace(
                accounts: [sampleAccount],
                methods: ["method"],
                events: ["event"],
                extensions: [
                    SessionNamespace.Extension(accounts: [], methods: ["otherMethod"], events: ["otherEvent"])
                ]
            )
        ]
        XCTAssertThrowsError(try Namespace.validate(namespace))
    }
    
    func testValidateAllNamespaces() {
        let namespace = [
            "eip155": SessionNamespace(
                accounts: [sampleAccount],
                methods: ["method"],
                events: ["event"],
                extensions: nil),
            "cosmos": SessionNamespace(
                accounts: [], methods: [], events: [], extensions: nil)
        ]
        XCTAssertThrowsError(try Namespace.validate(namespace))
    }
}
