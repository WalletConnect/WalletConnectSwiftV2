import XCTest
@testable import WalletConnectSign

final class BlockchainTests: XCTestCase {

    func testInitFromString() {
        // Valid chains
        XCTAssertNotNil(Blockchain("std:0"))
        XCTAssertNotNil(Blockchain("chainstd:8c3444cf8970a9e41a706fab93e7a6c4"))

        // Invalid chains
        XCTAssertNil(Blockchain("st:0"))
        XCTAssertNil(Blockchain("std:$"))
        XCTAssertNil(Blockchain("chainstdd:0"))
    }

    func testInitFromNamespaceAndReference() {
        // Valid chains
        XCTAssertNotNil(Blockchain(namespace: "std", reference: "0"))
        XCTAssertNotNil(Blockchain(namespace: "chainstd", reference: "8c3444cf8970a9e41a706fab93e7a6c4"))

        // Invalid chains
        XCTAssertNil(Blockchain(namespace: "st", reference: "0"))
        XCTAssertNil(Blockchain(namespace: "std", reference: ""))
        XCTAssertNil(Blockchain(namespace: "std", reference: "8c3444cf8970a9e41a706fab93e7a6c44"))
    }

    func testAbsoluteString() {
        let chainString = "chainstd:8c3444cf8970a9e41a706fab93e7a6c4"
        let blockchain = Blockchain(chainString)!
        XCTAssertEqual(blockchain.absoluteString, chainString)
    }

    func testCodable() throws {
        let blockchain = Blockchain("chainstd:8c3444cf8970a9e41a706fab93e7a6c4")!
        let encoded = try JSONEncoder().encode(blockchain)
        let decoded = try JSONDecoder().decode(Blockchain.self, from: encoded)
        XCTAssertEqual(blockchain, decoded)
    }
}
