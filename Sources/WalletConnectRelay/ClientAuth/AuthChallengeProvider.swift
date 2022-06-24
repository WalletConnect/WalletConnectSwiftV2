import Foundation

protocol AuthChallengeProviding {
    func getChallenge(for clientId: String) async throws -> AuthChallenge
}

struct AuthChallenge: Decodable {
    let nonce: String
}

actor AuthChallengeProvider: AuthChallengeProviding {

    var client: HTTPClient

    init(client: HTTPClient) {
        self.client = client
    }

    func getChallenge(for clientId: String) async throws -> AuthChallenge {
        let endpoint = Endpoint(
            path: "/auth-nonce",
            queryParameters: [URLQueryItem(name: "idd", value: clientId)])
        return try await client.request(AuthChallenge.self, at: endpoint)
    }
}
