import Foundation
import HTTPClient

final class ListingsNetworkService {

    struct ListingsResponse: Codable {
        let projects: [String: Listing]
    }

    func getListings() async throws -> [Listing] {
        let httpClient = HTTPNetworkClient(host: "explorer-api.walletconnect.com")
        let response = try await httpClient.request(ListingsResponse.self, at: ListingsAPI.notifyDApps)
        return response.projects.values.compactMap { $0 }
    }
}
