import XCTest
@testable import WalletConnectSign
@testable import WalletConnectUtils

class SessionNamespaceBuilderTests: XCTestCase {
    var sessionNamespaceBuilder: SessionNamespaceBuilder!
    var logger: ConsoleLogging!

    // dedoded recap: {"att":{"eip155":{"request/eth_sign":[],"request/personal_sign":[],"request/eth_signTypedData":[]}}}
    let recapUrn = "urn:recap:eyJhdHQiOnsiZWlwMTU1Ijp7InJlcXVlc3QvZXRoX3NpZ24iOltdLCJyZXF1ZXN0L3BlcnNvbmFsX3NpZ24iOltdLCJyZXF1ZXN0L2V0aF9zaWduVHlwZWREYXRhIjpbXX19fQ=="

    override func setUp() {
        super.setUp()
        logger = ConsoleLoggerMock()
        sessionNamespaceBuilder = SessionNamespaceBuilder(logger: logger)
    }

    override func tearDown() {
        sessionNamespaceBuilder = nil
        logger = nil
        super.tearDown()
    }


    func testBuildSessionNamespaces_ValidCacaos_ReturnsExpectedNamespace() {
        let expectedSessionNamespace = SessionNamespace(
            accounts: Set([
                Account("eip155:1:0x000a10343Bcdebe21283c7172d67a9a113E819C5")!,
                Account("eip155:137:0x000a10343Bcdebe21283c7172d67a9a113E819C5")!
            ]),
            methods: ["personal_sign", "eth_signTypedData", "eth_sign"],
            events: []
        )
        let cacaos = [
            Cacao.stub(account: Account("eip155:1:0x000a10343Bcdebe21283c7172d67a9a113E819C5")!, resources: [recapUrn]),
            Cacao.stub(account: Account("eip155:137:0x000a10343Bcdebe21283c7172d67a9a113E819C5")!, resources: [recapUrn])
        ]

        do {
            let namespaces = try sessionNamespaceBuilder.buildSessionNamespaces(cacaos: cacaos)
            XCTAssertEqual(namespaces.count, 1, "There should be one namespace")
            XCTAssertEqual(expectedSessionNamespace, namespaces.first!.value, "The namespace is equal to the expected one")
        } catch {
            XCTFail("Expected successful namespace creation, but received error: \(error)")
        }
    }

    func testMutlipleRecapsInCacaoWhereOnlyOneIsSessionRecap() {
        let expectedSessionNamespace = SessionNamespace(
            accounts: Set([
                Account("eip155:1:0x000a10343Bcdebe21283c7172d67a9a113E819C5")!
            ]),
            methods: ["personal_sign", "eth_signTypedData", "eth_sign"],
            events: []
        )
        let cacao = Cacao.stub(account: Account("eip155:1:0x000a10343Bcdebe21283c7172d67a9a113E819C5")!, resources: ["urn:recap:eyJh", recapUrn, "urn:recap:eyJh"])

        do {
            let namespaces = try sessionNamespaceBuilder.buildSessionNamespaces(cacaos: [cacao])
            XCTAssertEqual(namespaces.count, 1, "There should be one namespace")
            XCTAssertEqual(expectedSessionNamespace, namespaces.first!.value, "The namespace is equal to the expected one")
        } catch {
            XCTFail("Expected successful namespace creation, but received error: \(error)")
        }
    }

    func testBuildSessionNamespaces_MalformedRecap_ThrowsMalformedRecapError() {
        let validResources = ["https://example.com/my-web2-claim.json", recapUrn]
        let invalidResources = ["https://example.com/my-web2-claim.json"]

        let validCacao = Cacao.stub(account: Account("eip155:1:0x000a10343Bcdebe21283c7172d67a9a113E819C5")!, resources: validResources)
        let invalidCacao = Cacao.stub(account: Account("eip155:137:0x000a10343Bcdebe21283c7172d67a9a113E819C5")!, resources: invalidResources)

        XCTAssertThrowsError(try sessionNamespaceBuilder.buildSessionNamespaces(cacaos: [validCacao, invalidCacao])) { error in
            guard let sessionError = error as? SessionNamespaceBuilder.Errors else {
                return XCTFail("Expected a SessionNamespaceBuilder.Errors")
            }

            XCTAssertEqual(sessionError, SessionNamespaceBuilder.Errors.malformedRecap, "Expected a malformedRecap error")
        }
    }


}
