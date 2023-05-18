import Foundation

struct ExplorerApi {
    let getListings: @Sendable (_ projectID: String) async throws -> ListingsResponse
}

extension ExplorerApi {
    static func live(httpService: HttpService = .live) -> Self {
        .init(
            getListings: { projectId in

                let endpoint = Endpoint.bare(
                    path: "/w3m/v1/getiOSListings",
                    queryItems: [
                        .init(name: "projectId", value: projectId),
                        .init(name: "page", value: "1"),
                        .init(name: "entries", value: "9"),
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
