import Foundation
import Combine

import Web3Wallet
import WalletConnectNotify

final class MainInteractor {

    var sessionProposalPublisher: AnyPublisher<(proposal: Session.Proposal, context: VerifyContext?), Never> {
        return Web3Wallet.instance.sessionProposalPublisher
    }
    
    var sessionRequestPublisher: AnyPublisher<(request: Request, context: VerifyContext?), Never> {
        return Web3Wallet.instance.sessionRequestPublisher
    }
    
    var authenticateRequestPublisher: AnyPublisher<(request: AuthenticationRequest, context: VerifyContext?), Never> {
        return Web3Wallet.instance.authenticateRequestPublisher
    }
}
