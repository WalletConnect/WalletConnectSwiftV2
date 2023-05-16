import Foundation

struct ExplorerApi {
    let getMobileListings: @Sendable (_ projectID: String) async throws -> ListingsResponse
}

extension ExplorerApi {
    static func live(httpService: HttpService = .live) -> Self {
        .init(
            getMobileListings: { projectId in

                let endpoint = Endpoint.bare(
                    path: "/w3m/v1/getMobileListings",
                    queryItems: [
                        .init(name: "projectId", value: projectId),
                        .init(name: "page", value: "1"),
                        .init(name: "entries", value: "9"),
                        .init(name: "platforms", value: "ios,mac"),
                    ],
                    method: .GET,
                    host: "explorer-api.walletconnect.com"
                )

                let response = try await httpService.performRequest(endpoint)

                switch response {
                case let .success(data):
                    
                    let listings = try JSONDecoder().decode(ListingsResponse.self, from: data)
                    
                    return listings
                case let .failure(error):
                    throw error
                }
            }
        )
    }
}
