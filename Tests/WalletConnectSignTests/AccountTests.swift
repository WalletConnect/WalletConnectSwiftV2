import XCTest
@testable import WalletConnectSign

final class AccountTests: XCTestCase {

    func testInitFromString() {
        // Valid accounts
        XCTAssertNotNil(Account("std:0:0"))
        XCTAssertNotNil(Account("chainstd:8c3444cf8970a9e41a706fab93e7a6c4:6d9b0b4b9994e8a6afbd3dc3ed983cd51c755afb27cd1dc7825ef59c134a39f7"))

        // Invalid accounts
        XCTAssertNil(Account("std:0:$"))
        XCTAssertNil(Account("std:$:0"))
        XCTAssertNil(Account("st:0:0"))
    }

    func testInitFromChainAndAddress() {
        // Valid accounts
        XCTAssertNotNil(Account(chainIdentifier: "std:0", address: "0"))
        XCTAssertNotNil(Account(chainIdentifier: "chainstd:8c3444cf8970a9e41a706fab93e7a6c4", address: "6d9b0b4b9994e8a6afbd3dc3ed983cd51c755afb27cd1dc7825ef59c134a39f7"))

        // Invalid accounts
        XCTAssertNil(Account(chainIdentifier: "std:0", address: ""))
        XCTAssertNil(Account(chainIdentifier: "std", address: "0"))
    }

    func testInitFromBlockchain() {
        let chain = Blockchain("std:0")!

        // Valid accounts
        XCTAssertNotNil(Account(blockchain: chain, address: "0"))
        XCTAssertNotNil(Account(blockchain: chain, address: "6d9b0b4b9994e8a6afbd3dc3ed983cd51c755afb27cd1dc7825ef59c134a39f7"))

        // Invalid accounts
        XCTAssertNil(Account(blockchain: chain, address: ""))
        XCTAssertNil(Account(blockchain: chain, address: "$"))
    }

    func testBlockchainIdentifier() {
        let account = Account("eip155:1:0xab16a96d359ec26a11e2c2b3d8f8b8942d5bfcdb")!
        XCTAssertEqual(account.blockchainIdentifier, "eip155:1")
    }

    func testBlockchainExtraction() {
        let account = Account("eip155:1:0xab16a96d359ec26a11e2c2b3d8f8b8942d5bfcdb")!
        let blockchain = account.blockchain
        XCTAssertEqual(account.namespace, blockchain.namespace)
        XCTAssertEqual(account.reference, blockchain.reference)
    }

    func testAbsoluteString() {
        let accountString = "eip155:1:0xab16a96d359ec26a11e2c2b3d8f8b8942d5bfcdb"
        let account = Account(accountString)!
        XCTAssertEqual(account.absoluteString, accountString)
    }

    func testCodable() throws {
        let account = Account("eip155:1:0xab16a96d359ec26a11e2c2b3d8f8b8942d5bfcdb")!
        let encoded = try JSONEncoder().encode(account)
        let decoded = try JSONDecoder().decode(Account.self, from: encoded)
        XCTAssertEqual(account, decoded)
    }
}
