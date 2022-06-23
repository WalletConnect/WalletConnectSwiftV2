import Foundation

protocol AuthChallengeProviding {
    func getChallenge(for clientId: String) async throws -> String
}

actor AuthChallengeProvider: AuthChallengeProviding {
    func getChallenge(for clientId: String) async throws -> String {
        fatalError("not implemented")
    }
}
