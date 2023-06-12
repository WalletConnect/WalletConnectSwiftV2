
import Combine
import Foundation

protocol ModalSheetInteractor {
    func getListings() async throws -> [Listing]
    func createPairingAndConnect() async throws -> WalletConnectURI?
    
    var sessionSettlePublisher: AnyPublisher<Session, Never> { get }
    var sessionRejectionPublisher: AnyPublisher<(Session.Proposal, Reason), Never> { get }
}

final class DefaultModalSheetInteractor: ModalSheetInteractor {
    
    lazy var sessionSettlePublisher: AnyPublisher<Session, Never> = Web3Modal.instance.sessionSettlePublisher
    lazy var sessionRejectionPublisher: AnyPublisher<(Session.Proposal, Reason), Never> = Web3Modal.instance.sessionRejectionPublisher
    
    func getListings() async throws -> [Listing] {
        
        let httpClient = HTTPNetworkClient(host: "explorer-api.walletconnect.com")
        let response = try await httpClient.request(
            ListingsResponse.self,
            at: ExplorerAPI.getListings(projectId: Web3Modal.config.projectId)
        )
    
        return response.listings.values.compactMap { $0 }
    }
    
    func createPairingAndConnect() async throws -> WalletConnectURI? {
        try await Web3Modal.instance.connect(topic: nil)
    }
}
