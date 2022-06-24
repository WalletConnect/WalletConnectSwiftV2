import Foundation

protocol AuthChallengeProviding {
    func getChallenge(for clientId: String) throws -> String
}

actor AuthChallengeProvider: AuthChallengeProviding {
    func getChallenge(for clientId: String) async throws -> String {
        fatalError("not implemented")
//        let endpoint = Endpoint(
//            path: "/auth-nonce",
//            queryParameters: [URLQueryItem(name: "idd", value: clientId)])
    }
}

struct Endpoint {
    let path: String
    let queryParameters: [URLQueryItem]
}

struct AuthNonce: Decodable {
    let nonce: String
}
