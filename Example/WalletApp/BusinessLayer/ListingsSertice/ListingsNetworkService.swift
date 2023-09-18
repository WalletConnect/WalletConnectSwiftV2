import Foundation
import HTTPClient

final class ListingsNetworkService {

    struct ListingsResponse: Codable {
        let listings: [String: Listing]
    }

    func getListings() async throws -> [Listing] {
        let httpClient = HTTPNetworkClient(host: "explorer-api.walletconnect.com")
        let response = try await httpClient.request(ListingsResponse.self, at: ListingsAPI.notifyDApps)
        return response.listings.values.compactMap { $0 }
    }
}
