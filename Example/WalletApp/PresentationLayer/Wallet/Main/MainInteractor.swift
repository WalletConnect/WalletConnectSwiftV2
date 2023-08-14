import Foundation
import Combine

import Web3Wallet
import WalletConnectPush

final class MainInteractor {
    var pushRequestPublisher: AnyPublisher<(id: RPCID, account: Account, metadata: AppMetadata), Never> {
        return Push.wallet.requestPublisher
    }
    
    var sessionProposalPublisher: AnyPublisher<(proposal: Session.Proposal, context: VerifyContext?), Never> {
        return Web3Wallet.instance.sessionProposalPublisher
    }
    
    var sessionRequestPublisher: AnyPublisher<(request: Request, context: VerifyContext?), Never> {
        return Web3Wallet.instance.sessionRequestPublisher
    }
    
    var requestPublisher: AnyPublisher<(request: AuthRequest, context: VerifyContext?), Never> {
        return Web3Wallet.instance.authRequestPublisher
    }
}
