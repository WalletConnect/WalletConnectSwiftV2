import Combine

import Web3Wallet

final class ConnectionDetailsInteractor {
    func disconnectSession(session: Session) async throws {
        try await Web3Wallet.instance.disconnect(topic: session.topic)
    }
}
