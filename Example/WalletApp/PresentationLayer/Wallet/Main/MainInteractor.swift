import Foundation
import Combine

import Web3Wallet
import WalletConnectPush

final class MainInteractor {
    var pushRequestPublisher: AnyPublisher<(id: RPCID, account: Account, metadata: AppMetadata), Never> {
        return Push.wallet.requestPublisher
    }
}
