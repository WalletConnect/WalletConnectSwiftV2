import Foundation
@testable import WalletConnectRelay
import Foundation

actor AuthChallengeProviderMock: AuthChallengeProviding {
    var challange: String!

    func getChallenge(for clientId: String) async throws -> String {
        return challange
    }
}
