import Combine

import Web3Wallet
import WalletConnectPush

final class WalletInteractor {
    var sessionsPublisher: AnyPublisher<[Session], Never> {
        return Web3Wallet.instance.sessionsPublisher
    }

    func getSessions() -> [Session] {
        return Web3Wallet.instance.getSessions()
    }
    
    func pair(uri: WalletConnectURI) async throws {
        try await Web3Wallet.instance.pair(uri: uri)
    }
    
    func disconnectSession(session: Session) async throws {
        try await Web3Wallet.instance.disconnect(topic: session.topic)
    }
    
    func getPendingProposals() -> [(proposal: Session.Proposal, context: VerifyContext?)] {
        Web3Wallet.instance.getPendingProposals()
    }
    
    func getPendingRequests() -> [(request: Request, context: VerifyContext?)] {
        Web3Wallet.instance.getPendingRequests()
    }
}
