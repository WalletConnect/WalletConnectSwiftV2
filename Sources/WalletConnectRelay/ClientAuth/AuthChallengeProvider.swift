import Foundation

protocol AuthChallengeProviding {
    func getChallenge(for clientId: String) throws -> String
}

struct AuthChallengeProvider: AuthChallengeProviding {
    func getChallenge(for clientId: String) throws -> String {
        // TODO: Implement me
        return "AuthChallenge"
    }
}
