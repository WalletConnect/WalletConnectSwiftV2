import Foundation
import XCTest
@testable import Auth
import secp256k1
import Web3
import WalletConnectUtils

class SignerTest: XCTestCase {

    private let signer = Signer()

    private let message = "Message".data(using: .utf8)!
    private let privateKey = Data(hex: "305c6cde3846927892cd32762f6120539f3ec74c9e3a16b9b798b1e85351ae2a")
    private let signature = Data(hex: "f7d00a04559bff462f02194874b1ae7d4a8f0461acbe4be73386ebe982a9b9dc599abf31107e1ba708a3ec72499f1fd73dd390c5ca1a3084abe176de0529d00e00")
    private var address = "0x15bca56b6e2728aec2532df9d436bd1600e86688"

    func testValidSignature() throws {
        let result = try signer.sign(message: message, with: privateKey)

        XCTAssertEqual(signature, result)
        XCTAssertTrue(try signer.isValid(signature: result, message: message, address: address))
    }

    func testInvalidMessage() throws {
        let message = "Message One".data(using: .utf8)!

        XCTAssertFalse(try signer.isValid(signature: signature, message: message, address: address))
    }

    func testInvalidPubKey() throws {
        let address = "0xBAc675C310721717Cd4A37F6cbeA1F081b1C2a07"

        XCTAssertFalse(try signer.isValid(signature: signature, message: message, address: address))
    }

    func testInvalidSignature() throws {
        let signature = Data(hex: "86deb09d045608f2753ef12f46e8da5fc2559e3a9162e580df3e62c875df7c3f64433462a59bc4ff38ce52412bff10527f4b99cc078f63ef2bb4a6f7427080aa01")

        XCTAssertFalse(try signer.isValid(signature: signature, message: message, address: address))
    }

    func testSignerAddressFromIss() throws {
        let iss = "did:pkh:eip155:1:0xBAc675C310721717Cd4A37F6cbeA1F081b1C2a07"

        XCTAssertEqual(try DIDPKH(iss: iss).account, Account("eip155:1:0xBAc675C310721717Cd4A37F6cbeA1F081b1C2a07")!)
    }

    func testSignerAddressFromAccount() throws {
        let account = Account("eip155:1:0xBAc675C310721717Cd4A37F6cbeA1F081b1C2a07")!

        XCTAssertEqual(DIDPKH(account: account).iss, "did:pkh:eip155:1:0xBAc675C310721717Cd4A37F6cbeA1F081b1C2a07")
    }
}
