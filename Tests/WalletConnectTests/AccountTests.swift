import XCTest
@testable import WalletConnect

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
    
    func testInitCAIP10Conformance() {
        XCTAssertTrue(Account((namespace: "std", reference: "0", address: "0")).isCAIP10Conformant)
        
        XCTAssertFalse(Account((namespace: "st", reference: "0", address: "0")).isCAIP10Conformant)
        XCTAssertFalse(Account((namespace: "std", reference: "", address: "0")).isCAIP10Conformant)
        XCTAssertFalse(Account((namespace: "std", reference: "0", address: "")).isCAIP10Conformant)
    }
    
    func testBlockchainIdentifier() {
        let account = Account("eip155:1:0xab16a96d359ec26a11e2c2b3d8f8b8942d5bfcdb")!
        XCTAssertEqual(account.blockchainIdentifier, "eip155:1")
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

extension AccountTests {
    func testInit_whenIsCAIP10_EthereumMainnet() {
        XCTAssertTrue(Account((
            namespace: "eip155",
            reference: "1",
            address: "0xab16a96d359ec26a11e2c2b3d8f8b8942d5bfcdb"
        )).isCAIP10Conformant)
    }
        
    func testInit_whenIsCAIP10_BitcoinMainnet() {
        XCTAssertTrue(Account((
            namespace: "bip122",
            reference: "000000000019d6689c085ae165831e93",
            address: "128Lkh3S7CkDTBZ8W7BbpsN3YYizJMp8p6"
        )).isCAIP10Conformant)
    }
        
    func testInit_whenIsCAIP10_CosmosHub() {
        XCTAssertTrue(Account((
            namespace: "bip122",
            reference: "000000000019d6689c085ae165831e93",
            address: "128Lkh3S7CkDTBZ8W7BbpsN3YYizJMp8p6"
        )).isCAIP10Conformant)
    }
    
    func testInit_whenIsCAIP10_KusamaNetwork() {
        XCTAssertTrue(Account((
            namespace: "polkadot",
            reference: "b0a8d493285c2df73290dfb7e61f870f",
            address: "5hmuyxw9xdgbpptgypokw4thfyoe3ryenebr381z9iaegmfy"
        )).isCAIP10Conformant)
    }
        
    func testInit_whenIsCAIP10_DummyMaxLenght() {
        // Dummy max length (64+1+8+1+32 = 106 chars/bytes)
        XCTAssertTrue(Account((
            namespace: "chainstd",
            reference: "8c3444cf8970a9e41a706fab93e7a6c4",
            address: "6d9b0b4b9994e8a6afbd3dc3ed983cd51c755afb27cd1dc7825ef59c134a39f7"
        )).isCAIP10Conformant)
    }
}
