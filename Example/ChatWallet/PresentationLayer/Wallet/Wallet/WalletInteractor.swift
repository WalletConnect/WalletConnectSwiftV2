import Combine

import Web3Wallet

final class WalletInteractor {
    var requestPublisher: AnyPublisher<AuthRequest, Never> {
        return Web3Wallet.instance.authRequestPublisher
    }
    
    var sessionsPublisher: AnyPublisher<[Session], Never> {
        return Web3Wallet.instance.sessionsPublisher
    }
    
    func getSessions() -> [Session] {
        return Web3Wallet.instance.getSessions()
    }
    
    func pair(uri: WalletConnectURI) async throws {
        try await Web3Wallet.instance.pair(uri: uri)
    }
}
