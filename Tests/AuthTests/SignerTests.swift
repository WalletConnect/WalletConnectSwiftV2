import Foundation
import XCTest
@testable import Auth
import secp256k1
import Web3
import WalletConnectUtils
import WalletConnectRelay

class SignerTest: XCTestCase {

    private let signer = Signer()

    private let message = "\u{19}Ethereum Signed Message:\n7Message".data(using: .utf8)!
    private let privateKey = Data(hex: "305c6cde3846927892cd32762f6120539f3ec74c9e3a16b9b798b1e85351ae2a")
    private let signature = Data(hex: "66121e60cccc01fbf7fcba694a1e08ac5db35fb4ec6c045bedba7860445b95c021cad2c595f0bf68ff896964c7c02bb2f3a3e9540e8e4595c98b737ce264cc541b")
    private var address = "0x15bca56b6e2728aec2532df9d436bd1600e86688"

    func testValidSignature() throws {
        let result = try signer.sign(message: message, with: privateKey)

        XCTAssertEqual(signature.toHexString(), result.toHexString())
    }

    private func prefixed(_ message: Data) -> Data {
        return "\u{19}Ethereum Signed Message:\n\(message.count)"
            .data(using: .utf8)! + message
    }

//    func testEtherscanSignature() async throws {
//        let addressFromEtherscan = "0x6721591d424c18b7173d55895efa1839aa57d9c2"
//        let message = "[Etherscan.io 12/08/2022 09:26:23] I, hereby verify that I am the owner/creator of the address [0x7e77dcb127f99ece88230a64db8d595f31f1b068]"
//        let signedMessageFromEtherscan = message.data(using: .utf8)!
//        let signatureHashFromEtherscan = Data(hex: "60eb9cfe362210f1b4855f4865eafc378bd442c406de22354cc9f643fb84cb265b7f6d9d10b13199e450558c328814a9038884d9993d9feb79b727366736853d1b")
//        XCTAssertTrue(try signer.isValid(
//            signature: signatureHashFromEtherscan,
//            message: signedMessageFromEtherscan,
//            address: addressFromEtherscan
//        ))
//
//        let client = HTTPClient(host: "rpc.walletconnect.com")
//        let service = EIP1271Verifier(projectId: "28fc11c6a12a4184bc8e9c371edff2bc", httpClient: client)
//        try await service.verify(
//            signature: Data(hex: "c1505719b2504095116db01baaf276361efd3a73c28cf8cc28dabefa945b8d536011289ac0a3b048600c1e692ff173ca944246cf7ceb319ac2262d27b395c82b1c"),
//            messageHash: Data(hex: "3aaa8393796c7388e4e062861d8238503de7584c977676fe9d8d551c30e11f84"),
//            address: "0x2faf83c542b68f1b4cdc0e770e8cb9f567b08f71"
//        )
//    }
//
//    func testInvalidMessage() throws {
//        let message = "Message One".data(using: .utf8)!
//
//        XCTAssertFalse(try signer.isValid(signature: signature, message: message, address: address))
//    }
//
//    func testInvalidPubKey() throws {
//        let address = "0xBAc675C310721717Cd4A37F6cbeA1F081b1C2a07"
//
//        XCTAssertFalse(try signer.isValid(signature: signature, message: message, address: address))
//    }
//
//    func testInvalidSignature() throws {
//        let signature = Data(hex: "86deb09d045608f2753ef12f46e8da5fc2559e3a9162e580df3e62c875df7c3f64433462a59bc4ff38ce52412bff10527f4b99cc078f63ef2bb4a6f7427080aa01")
//
//        XCTAssertFalse(try signer.isValid(signature: signature, message: message, address: address))
//    }

    func testSignerAddressFromIss() throws {
        let iss = "did:pkh:eip155:1:0xBAc675C310721717Cd4A37F6cbeA1F081b1C2a07"

        XCTAssertEqual(try DIDPKH(iss: iss).account, Account("eip155:1:0xBAc675C310721717Cd4A37F6cbeA1F081b1C2a07")!)
    }

    func testSignerAddressFromAccount() throws {
        let account = Account("eip155:1:0xBAc675C310721717Cd4A37F6cbeA1F081b1C2a07")!

        XCTAssertEqual(DIDPKH(account: account).iss, "did:pkh:eip155:1:0xBAc675C310721717Cd4A37F6cbeA1F081b1C2a07")
    }
}
