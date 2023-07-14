import Combine
import Foundation
import WalletConnectSign
import WalletConnectUtils
@testable import WalletConnectModal
@testable import WalletConnectSign

final class ModalSheetInteractorMock: ModalSheetInteractor {
    
    var listings: [Listing]
    
    init(listings: [Listing] = Listing.stubList) {
        self.listings = listings
    }

    func getListings() async throws -> [Listing] {
        listings
    }
    
    func createPairingAndConnect() async throws -> WalletConnectURI? {
        .init(topic: "foo", symKey: "bar", relay: .init(protocol: "irn", data: nil))
    }
    
    var sessionSettlePublisher: AnyPublisher<Session, Never> {
        Result.Publisher(Session(topic: "", pairingTopic: "", peer: .stub(), requiredNamespaces: [:], namespaces: [:], sessionProperties: nil, expiryDate: Date()))
            .eraseToAnyPublisher()
    }
    
    var sessionRejectionPublisher: AnyPublisher<(Session.Proposal, Reason), Never> {
        let sessionProposal = Session.Proposal(
            id: "",
            pairingTopic: "",
            proposer: AppMetadata(name: "", description: "", url: "", icons: []),
            requiredNamespaces: [:],
            optionalNamespaces: nil,
            sessionProperties: nil,
            proposal: SessionProposal(relays: [], proposer: Participant(publicKey: "", metadata: AppMetadata(name: "", description: "", url: "", icons: [])), requiredNamespaces: [:], optionalNamespaces: [:], sessionProperties: [:])
        )
        
        return Result.Publisher((sessionProposal, SignReasonCode.userRejectedChains))
            .eraseToAnyPublisher()
    }
}
