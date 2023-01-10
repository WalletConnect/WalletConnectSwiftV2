import Combine

import Web3Wallet

final class ConnectionDetailsInteractor {
    var requestPublisher: AnyPublisher<AuthRequest, Never> {
        return Web3Wallet.instance.authRequestPublisher
    }
    
    func pair(uri: WalletConnectURI) async throws {
        try await Web3Wallet.instance.pair(uri: uri)
    }
    
    func disconnectSession(session: Session) async throws {
        try await Web3Wallet.instance.disconnect(topic: session.topic)
    }
}
