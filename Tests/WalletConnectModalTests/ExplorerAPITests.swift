import TestingUtils
@testable import WalletConnectModal
import XCTest

final class ExplorerAPITests: XCTestCase {
    
    func testCorrectMappingOfWalletIds() throws {
        
        let request = ExplorerAPI
            .getListings(projectId: "123", metadata: .stub(), recommendedIds: ["foo", "bar"], excludedIds: ["boo", "far"])
            .resolve(for: "www.google.com")
        
        XCTAssertEqual(request?.allHTTPHeaderFields?["Referer"], "Wallet Connect")
        
        XCTAssertEqual(request?.url?.queryParameters, [
            "projectId": "123",
            "recommendedIds": "foo,bar",
            "excludedIds": "boo,far",
            "sdkVersion": EnvironmentInfo.sdkName,
            "sdkType": "wcm"
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
