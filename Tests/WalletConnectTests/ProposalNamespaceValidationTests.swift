import XCTest
@testable import WalletConnect

final class ProposalNamespaceValidationTests: XCTestCase {
    
    func testValidNamespace() {
        let namespace = [
            "eip155": ProposalNamespace(
                chains: [Blockchain("eip155:1")!],
                methods: ["method"],
                events: ["event"],
                extensions: [
                    ProposalNamespace.Extension(chains: [Blockchain("eip155:137")!], methods: ["otherMethod"], events: ["otherEvent"])
                ]
            )
        ]
        XCTAssertNoThrow(try NamespaceValidator.validate(namespace))
    }
    
    func testChainsMustNotNotBeEmpty() {
        let namespace = [
            "eip155": ProposalNamespace(
                chains: [],
                methods: ["method"],
                events: ["event"],
                extensions: nil)
        ]
        XCTAssertThrowsError(try NamespaceValidator.validate(namespace))
    }
    
    func testAllowsEmptyMethods() {
        let namespace = [
            "eip155": ProposalNamespace(
                chains: [Blockchain("eip155:1")!],
                methods: [],
                events: ["event"],
                extensions: nil)
        ]
        XCTAssertNoThrow(try NamespaceValidator.validate(namespace))
    }
    
    func testAllowsEmptyEvents() {
        let namespace = [
            "eip155": ProposalNamespace(
                chains: [Blockchain("eip155:1")!],
                methods: ["method"],
                events: [],
                extensions: nil)
        ]
        XCTAssertNoThrow(try NamespaceValidator.validate(namespace))
    }
    
    func testAllChainsContainsNamespacePrefix() {
        let validNamespace = [
            "eip155": ProposalNamespace(
                chains: [Blockchain("eip155:1")!, Blockchain("eip155:137")!, Blockchain("eip155:10")!],
                methods: ["method"],
                events: ["event"],
                extensions: nil)
        ]
        let invalidNamespace = [
            "eip155": ProposalNamespace(
                chains: [Blockchain("eip155:1")!, Blockchain("cosmos:cosmoshub-4")!],
                methods: ["method"],
                events: ["event"],
                extensions: nil)
        ]
        XCTAssertNoThrow(try NamespaceValidator.validate(validNamespace))
        XCTAssertThrowsError(try NamespaceValidator.validate(invalidNamespace))
    }
    
    func testExtensionChainsMustNotBeEmpty() {
        let namespace = [
            "eip155": ProposalNamespace(
                chains: [Blockchain("eip155:1")!],
                methods: ["method"],
                events: ["event"],
                extensions: [
                    ProposalNamespace.Extension(chains: [], methods: ["otherMethod"], events: ["otherEvent"])
                ]
            )
        ]
        XCTAssertThrowsError(try NamespaceValidator.validate(namespace))
    }
    
    func testValidateAllNamespaces() {
        let namespace = [
            "eip155": ProposalNamespace(
                chains: [Blockchain("eip155:1")!],
                methods: ["method"],
                events: ["event"],
                extensions: nil),
            "cosmos": ProposalNamespace(
                chains: [], methods: [], events: [], extensions: nil)
        ]
        XCTAssertThrowsError(try NamespaceValidator.validate(namespace))
    }
}
