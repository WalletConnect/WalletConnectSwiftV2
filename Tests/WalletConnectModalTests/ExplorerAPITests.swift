import TestingUtils
@testable import WalletConnectModal
import XCTest

final class ExplorerAPITests: XCTestCase {

    func testCorrectUserAgent() throws {
        
        let request = ExplorerAPI
            .getListings(projectId: "foo", metadata: .stub(), recommendedIds: [], excludedIds: [])
            .resolve(for: "www.google.com")
        
        XCTAssertEqual(request?.allHTTPHeaderFields?["Referer"], "Wallet Connect")
        // Should look something like this: w3m-ios-1.0.0/swift-v1.6.8/iOS-16.1
        XCTAssertTrue(request?.allHTTPHeaderFields?["User-Agent"]?.starts(with: "w3m-ios-1.0.0/swift-v") ?? false)
    }
    
    func testCorrectMappingOfWalletIds() throws {
        
        let request = ExplorerAPI
            .getListings(projectId: "123", metadata: .stub(), recommendedIds: ["foo", "bar"], excludedIds: ["boo", "far"])
            .resolve(for: "www.google.com")
        
        XCTAssertEqual(request?.url?.queryParameters, [
            "projectId": "123",
            "recommendedIds": "foo,bar",
            "excludedIds": "boo,far"
        ])
    }
}

private extension URL {
    
    var queryParameters: [String: String] {
        let urlComponents = URLComponents(url: self, resolvingAgainstBaseURL: false)
        guard let queryItems = urlComponents?.queryItems else { return [:] }
        var queryParams: [String: String] = [:]
        queryItems.forEach {
            queryParams[$0.name] = $0.value
        }
        return queryParams
    }
}
