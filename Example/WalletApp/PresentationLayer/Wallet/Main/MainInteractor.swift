import Combine
import Web3Wallet
import WalletConnectPush
import Foundation

final class MainInteractor {

    var sessionProposalPublisher: AnyPublisher<Session.Proposal, Never> {
        return Web3Wallet.instance.sessionProposalPublisher
    }

    var pushRequestPublisher: AnyPublisher<(id: RPCID, account: Account, metadata: AppMetadata), Never> {
        return Push.wallet.requestPublisher
    }
}
