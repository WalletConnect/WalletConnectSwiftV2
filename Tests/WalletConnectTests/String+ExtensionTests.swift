import XCTest
@testable import WalletConnect

final class StringExtensionTests: XCTestCase {
    
    func testGenericPasswordConvertible() {
        let string = UUID().uuidString.replacingOccurrences(of: "-", with: "")
        let restoredString = try? String(rawRepresentation: string.rawRepresentation)
        XCTAssertEqual(string, restoredString)
    }
    
    func testConformanceToCAIP2() {
        // Minimum and maximum cases
        XCTAssertTrue(String.conformsToCAIP2("std:0"), "Dummy min length (3+1+1 = 5 chars/bytes)")
        XCTAssertTrue(String.conformsToCAIP2("chainstd:8C3444cf8970a9e41a706fab93e7a6c4"), "Dummy max length (8+1+32 = 41 chars/bytes)")
        
        // Invalid namespace formatting
        XCTAssertFalse(String.conformsToCAIP2("chainstdd:8c3444cf8970a9e41a706fab93e7a6c4"), "Namespace overflow")
        XCTAssertFalse(String.conformsToCAIP2("st:8c3444cf8970a9e41a706fab93e7a6c4"), "Namespace underflow")
        XCTAssertFalse(String.conformsToCAIP2("chain$td:8c3444cf8970a9e41a706fab93e7a6c4"), "Namespace uses special character")
        XCTAssertFalse(String.conformsToCAIP2("Chainstd:8c3444cf8970a9e41a706fab93e7a6c4"), "Namespace uses uppercase letter")
        XCTAssertFalse(String.conformsToCAIP2(":8c3444cf8970a9e41a706fab93e7a6c4"), "Empty namespace")
        
        // Invalid reference formatting
        XCTAssertFalse(String.conformsToCAIP2("chainstd:8c3444cf8970a9e41a706fab93e7a6c44"), "Reference overflow")
        XCTAssertFalse(String.conformsToCAIP2("chainstd:8c!444cf8970a9e41a706fab93e7a6c4"), "Reference uses special character")
        XCTAssertFalse(String.conformsToCAIP2("chainstd:"), "Empty reference")
        
        // Invalid identifier form
        XCTAssertFalse(String.conformsToCAIP2("chainstd8c3444cf8970a9e41a706fab93e7a6c4"), "No colon")
        XCTAssertFalse(String.conformsToCAIP2("chainstd:8c3444cf8970a9e41a706fab93e7a6c4:"), "Multiple colon in suffix")
        XCTAssertFalse(String.conformsToCAIP2("chainstd:8c3444cf8970a9e:41a706fab93e7a6c"), "Multiple colons")
        XCTAssertFalse(String.conformsToCAIP2(""), "Empty string")
    }
    
    func testRealExamplesConformanceToCAIP2() {
        XCTAssertTrue(String.conformsToCAIP2("eip155:1"), "Ethereum mainnet")
        XCTAssertTrue(String.conformsToCAIP2("bip122:000000000019d6689c085ae165831e93"), "Bitcoin mainnet")
        XCTAssertTrue(String.conformsToCAIP2("bip122:12a765e31ffd4059bada1e25190f6e98"), "Litecoin")
        XCTAssertTrue(String.conformsToCAIP2("bip122:fdbe99b90c90bae7505796461471d89a"), "Feathercoin (Litecoin fork)")
        XCTAssertTrue(String.conformsToCAIP2("cosmos:cosmoshub-2"), "Cosmos Hub (Tendermint + Cosmos SDK)")
        XCTAssertTrue(String.conformsToCAIP2("cosmos:Binance-Chain-Tigris"), "Binance chain (Tendermint + Cosmos SDK)")
        XCTAssertTrue(String.conformsToCAIP2("cosmos:iov-mainnet"), "IOV Mainnet (Tendermint + weave)")
        XCTAssertTrue(String.conformsToCAIP2("lip9:9ee11e9df416b18b"), "Lisk Mainnet (LIP-0009)")
    }
}

extension String {
    
    static func conformsToCAIP10(_ string: String) -> Bool {
        false
    }
}
