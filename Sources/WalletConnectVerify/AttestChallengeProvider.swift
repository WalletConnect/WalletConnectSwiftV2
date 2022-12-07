import Foundation

protocol AttestChallengeProviding {
    func getChallenge() async throws -> Data
}

class AttestChallengeProvider: AttestChallengeProviding {
    func getChallenge() async throws -> Data {
        return Data()
        fatalError("not implemented")
    }
}
