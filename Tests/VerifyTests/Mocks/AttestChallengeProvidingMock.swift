import Foundation
@testable import WalletConnectVerify

class AttestChallengeProvidingMock: AttestChallengeProviding {
    var challengeProvided = false
    func getChallenge() async throws -> Data {
        challengeProvided = true
        return Data()
    }
}
