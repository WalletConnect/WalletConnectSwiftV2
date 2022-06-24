import Foundation

protocol AuthChallengeProviding {
    func getChallenge(for clientId: String) throws -> String
}

actor AuthChallengeProvider: AuthChallengeProviding {

    struct AuthNonce: Decodable {
        let nonce: String
    }

    var client: HTTPClient

    init(client: HTTPClient) {
        self.client = client
    }

    func getChallenge(for clientId: String) async throws -> String {
        let endpoint = Endpoint(
            path: "/auth-nonce",
            queryParameters: [URLQueryItem(name: "idd", value: clientId)])
        return try await client.request(AuthNonce.self, at: endpoint).nonce
    }
}
