import TestingUtils
@testable import WalletConnectModal
import XCTest

final class ExplorerAPITests: XCTestCase {
    
    func testCorrectMappingOfWalletIds() throws {
        
        let request = Web3ModalAPI
            .getWallets(
                params: .init(
                    page: 2,
                    entries: 40,
                    search: "",
                    projectId: "123",
                    metadata: .stub(),
                    recommendedIds: ["foo", "bar"],
                    excludedIds: ["boo", "far"]
                )
            )
            .resolve(for: "www.google.com")
        
        XCTAssertEqual(request?.allHTTPHeaderFields?["Referer"], "Wallet Connect")
        XCTAssertEqual(request?.allHTTPHeaderFields?["x-sdk-version"], WalletConnectModal.Config.sdkVersion)
        XCTAssertEqual(request?.allHTTPHeaderFields?["x-sdk-type"], "wcm")
        XCTAssertEqual(request?.allHTTPHeaderFields?["x-project-id"], "123")
        
        XCTAssertEqual(request?.url?.queryParameters, [
            "recommendedIds": "foo,bar",
            "page": "2",
            "entries": "40",
            "platform": "ios",
            "excludedIds": "boo,far",
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
