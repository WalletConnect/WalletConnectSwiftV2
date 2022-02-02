import XCTest
@testable import WalletConnect

final class AccountTests: XCTestCase {
    
    func testInit() {
        // Valid accounts
        XCTAssertNotNil(Account(string: "std:0:0"))
        XCTAssertNotNil(Account(string: "chainstd:8c3444cf8970a9e41a706fab93e7a6c4:6d9b0b4b9994e8a6afbd3dc3ed983cd51c755afb27cd1dc7825ef59c134a39f7"))
        
        // Invalid accounts
        XCTAssertNil(Account(string: "std:0:$"))
        XCTAssertNil(Account(string: "std:$:0"))
        XCTAssertNil(Account(string: "st:0:0"))
    }
    
    func testBlockchainIdentifier() {
        let account = Account(string: "eip155:1:0xab16a96d359ec26a11e2c2b3d8f8b8942d5bfcdb")
        XCTAssertEqual(account?.blockchainIdentifier, "eip155:1")
    }
    
    func testAbsoluteString() {
        let accountString = "eip155:1:0xab16a96d359ec26a11e2c2b3d8f8b8942d5bfcdb"
        let account = Account(string: accountString)
        XCTAssertEqual(account?.absoluteString, accountString)
    }
}
