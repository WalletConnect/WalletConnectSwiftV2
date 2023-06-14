import TestingUtils
@testable import Web3Modal
import XCTest

final class ExplorerAPITests: XCTestCase {

    func testCorrectUserAgent() throws {
        
        let request = ExplorerAPI
            .getListings(projectId: "foo", metadata: .stub())
            .resolve(for: "www.google.com")
        
        XCTAssertEqual(request?.allHTTPHeaderFields?["Referer"], "Wallet Connect")
        // Should look something like this: w3m-ios-1.0.0/swift-v1.6.8/iOS-16.1
        XCTAssertTrue(request?.allHTTPHeaderFields?["User-Agent"]?.starts(with: "w3m-ios-1.0.0/swift-v") ?? false)
    }
}
