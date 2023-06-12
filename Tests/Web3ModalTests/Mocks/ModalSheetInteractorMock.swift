import Combine
import Foundation
import WalletConnectSign
import WalletConnectUtils
@testable import Web3Modal
@testable import WalletConnectSign

final class ModalSheetInteractorMock: ModalSheetInteractor {
    
    static let listingsStub: [Listing] = [
        Listing(id: UUID().uuidString, name: "Sample App", homepage: "https://example.com", order: 1, imageId: UUID().uuidString, app: Listing.App(ios: "https://example.com/download-ios", mac: "https://example.com/download-mac", safari: "https://example.com/download-safari"), mobile: Listing.Mobile(native: "sampleapp://deeplink", universal: "https://example.com/universal")),
        Listing(id: UUID().uuidString, name: "Awesome App", homepage: "https://example.com/awesome", order: 2, imageId: UUID().uuidString, app: Listing.App(ios: "https://example.com/download-ios", mac: "https://example.com/download-mac", safari: "https://example.com/download-safari"), mobile: Listing.Mobile(native: "awesomeapp://deeplink", universal: "https://example.com/awesome/universal")),
        Listing(id: UUID().uuidString, name: "Cool App", homepage: "https://example.com/cool", order: 3, imageId: UUID().uuidString, app: Listing.App(ios: "https://example.com/download-ios", mac: "https://example.com/download-mac", safari: "https://example.com/download-safari"), mobile: Listing.Mobile(native: "coolapp://deeplink", universal: "https://example.com/cool/universal"))
    ]
    
    var listings: [Listing]
    
    init(listings: [Listing] = ModalSheetInteractorMock.listingsStub) {
        self.listings = listings
    }

    func getListings() async throws -> [Listing] {
        listings
    }
    
    func createPairingAndConnect() async throws -> WalletConnectURI? {
        .init(topic: "foo", symKey: "bar", relay: .init(protocol: "irn", data: nil))
    }
    
    var sessionSettlePublisher: AnyPublisher<Session, Never> {
        Result.Publisher(Session(topic: "", pairingTopic: "", peer: .stub(), namespaces: [:], expiryDate: Date()))
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
