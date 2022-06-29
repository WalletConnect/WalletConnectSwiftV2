import Foundation
@testable import WalletConnectRelay
import Foundation

class AuthChallengeProviderMock: AuthChallengeProviding {
    var challenge: AuthChallenge!

    func getChallenge(for clientId: String) async throws -> AuthChallenge {
        return challenge
    }
}
