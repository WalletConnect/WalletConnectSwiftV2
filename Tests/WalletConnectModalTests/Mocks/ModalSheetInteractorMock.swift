import Combine
import Foundation
import WalletConnectSign
@testable import WalletConnectUtils
@testable import WalletConnectModal
@testable import WalletConnectSign

final class ModalSheetInteractorMock: ModalSheetInteractor {
    
    var wallets: [Wallet]
    
    init(wallets: [Wallet] = Wallet.stubList) {
        self.wallets = wallets
    }

    func getWallets(page: Int, entries: Int) async throws -> (Int, [Wallet]) {
        (1, wallets)
    }
    
    func createPairingAndConnect() async throws -> WalletConnectURI {
        .init(topic: "foo", symKey: "bar", relay: .init(protocol: "irn", data: nil), expiryTimestamp: 1706001526)
    }
    
    var sessionSettlePublisher: AnyPublisher<Session, Never> {
        Result.Publisher(Session(topic: "", pairingTopic: "", peer: .stub(), requiredNamespaces: [:], namespaces: [:], sessionProperties: nil, expiryDate: Date()))
            .eraseToAnyPublisher()
    }
    
    var sessionRejectionPublisher: AnyPublisher<(Session.Proposal, Reason), Never> {
        let sessionProposal = Session.Proposal(
            id: "",
            pairingTopic: "",
            proposer: AppMetadata(name: "", description: "", url: "", icons: [], redirect: try! AppMetadata.Redirect(native: "", universal: nil)),
            requiredNamespaces: [:],
            optionalNamespaces: nil,
            sessionProperties: nil,
            proposal: SessionProposal(relays: [], proposer: Participant(publicKey: "", metadata: try! AppMetadata(name: "", description: "", url: "", icons: [], redirect: AppMetadata.Redirect(native: "", universal: nil))), requiredNamespaces: [:], optionalNamespaces: [:], sessionProperties: [:])
        )
        
        return Result.Publisher((sessionProposal, SignReasonCode.userRejectedChains))
            .eraseToAnyPublisher()
    }
}
