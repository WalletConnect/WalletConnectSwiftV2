import Foundation
import XCTest
@testable import Auth
import WalletConnectRelay

class SignerTest: XCTestCase {

    private let signer = DefaultSignerFactory().createEthereumSigner()

    private let message = "\u{19}Ethereum Signed Message:\n7Message".data(using: .utf8)!
    private let privateKey = Data(hex: "305c6cde3846927892cd32762f6120539f3ec74c9e3a16b9b798b1e85351ae2a")
    private let signature = "0x66121e60cccc01fbf7fcba694a1e08ac5db35fb4ec6c045bedba7860445b95c021cad2c595f0bf68ff896964c7c02bb2f3a3e9540e8e4595c98b737ce264cc541b"
    private var address = "0x15bca56b6e2728aec2532df9d436bd1600e86688"

    func testValidSignature() throws {
        let result = try signer.sign(message: message, with: privateKey)

        XCTAssertEqual(signature, result.hex())
    }

    private func prefixed(_ message: Data) -> Data {
        return "\u{19}Ethereum Signed Message:\n\(message.count)"
            .data(using: .utf8)! + message
    }

    func testSignerAddressFromIss() throws {
        let iss = "did:pkh:eip155:1:0xBAc675C310721717Cd4A37F6cbeA1F081b1C2a07"

        XCTAssertEqual(try DIDPKH(did: iss).account, Account("eip155:1:0xBAc675C310721717Cd4A37F6cbeA1F081b1C2a07")!)
    }

    func testSignerAddressFromAccount() throws {
        let account = Account("eip155:1:0xBAc675C310721717Cd4A37F6cbeA1F081b1C2a07")!

        XCTAssertEqual(DIDPKH(account: account).string, "did:pkh:eip155:1:0xBAc675C310721717Cd4A37F6cbeA1F081b1C2a07")
    }
}
