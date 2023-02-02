import Foundation
import XCTest
@testable import Auth
@testable import WalletConnectSigner

class EIP191VerifierTests: XCTestCase {

    private let verifier = EIP191Verifier(signer: DefaultSignerFactory().createEthereumSigner())

    private let address = "0x15bca56b6e2728aec2532df9d436bd1600e86688"
    private let message = "\u{19}Ethereum Signed Message:\n7Message".data(using: .utf8)!
    private let signature = Data(hex: "66121e60cccc01fbf7fcba694a1e08ac5db35fb4ec6c045bedba7860445b95c021cad2c595f0bf68ff896964c7c02bb2f3a3e9540e8e4595c98b737ce264cc541b")

    func testVerify() async throws {
        try await verifier.verify(signature: signature, message: message, address: address)
    }

    func testEtherscanSignature() async throws {
        let address = "0x6721591d424c18b7173d55895efa1839aa57d9c2"
        let message = "\u{19}Ethereum Signed Message:\n139[Etherscan.io 12/08/2022 09:26:23] I, hereby verify that I am the owner/creator of the address [0x7e77dcb127f99ece88230a64db8d595f31f1b068]".data(using: .utf8)!
        let signature = Data(hex: "60eb9cfe362210f1b4855f4865eafc378bd442c406de22354cc9f643fb84cb265b7f6d9d10b13199e450558c328814a9038884d9993d9feb79b727366736853d1b")

        try await verifier.verify(signature: signature, message: message, address: address)
    }

    func testInvalidMessage() async throws {
        let message = Data(hex: "0xdeadbeaf")
        await XCTAssertThrowsErrorAsync(try await verifier.verify(signature: signature, message: message, address: address))
    }

    func testInvalidPubKey() async throws {
        let address = "0xBAc675C310721717Cd4A37F6cbeA1F081b1C2a07"
        await XCTAssertThrowsErrorAsync(try await verifier.verify(signature: signature, message: message, address: address))
    }

    func testInvalidSignature() async throws {
        let signature = Data(hex: "86deb09d045608f2753ef12f46e8da5fc2559e3a9162e580df3e62c875df7c3f64433462a59bc4ff38ce52412bff10527f4b99cc078f63ef2bb4a6f7427080aa01")

        await XCTAssertThrowsErrorAsync(try await verifier.verify(signature: signature, message: message, address: address))
    }
}
