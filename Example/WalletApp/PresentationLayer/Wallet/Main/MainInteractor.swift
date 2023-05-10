import Foundation
import Combine

import Web3Wallet
import WalletConnectPush

final class MainInteractor {

    var sessionProposalPublisher: AnyPublisher<(proposal: Session.Proposal, context: VerifyContext?), Never> {
        return Web3Wallet.instance.sessionProposalPublisher
    }

    var pushRequestPublisher: AnyPublisher<(id: RPCID, account: Account, metadata: AppMetadata), Never> {
        return Push.wallet.requestPublisher
    }
}
