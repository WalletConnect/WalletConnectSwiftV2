import Foundation

protocol AttestChallengeProviding {
    func getChallenge() async throws -> String
}

class AttestChallengeProvider: AttestChallengeProviding {
    func getChallenge() async throws -> String {
        fatalError("not implemented")
    }
}
