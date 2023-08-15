
import Combine
import Foundation

protocol ModalSheetInteractor {
    func getListings() async throws -> [Listing]
    func createPairingAndConnect() async throws -> WalletConnectURI?
    
    var sessionSettlePublisher: AnyPublisher<Session, Never> { get }
    var sessionRejectionPublisher: AnyPublisher<(Session.Proposal, Reason), Never> { get }
}

final class DefaultModalSheetInteractor: ModalSheetInteractor {
    
    lazy var sessionSettlePublisher: AnyPublisher<Session, Never> = WalletConnectModal.instance.sessionSettlePublisher
    lazy var sessionRejectionPublisher: AnyPublisher<(Session.Proposal, Reason), Never> = WalletConnectModal.instance.sessionRejectionPublisher
    
    func getListings() async throws -> [Listing] {
        
        let httpClient = HTTPNetworkClient(host: "explorer-api.walletconnect.com")
        let response = try await httpClient.request(
            ListingsResponse.self,
            at: ExplorerAPI.getListings(
                projectId: WalletConnectModal.config.projectId,
                metadata: WalletConnectModal.config.metadata,
                recommendedIds: WalletConnectModal.config.recommendedWalletIds,
                excludedIds: WalletConnectModal.config.excludedWalletIds
            )
        )
    
        return response.listings.values.compactMap { $0 }
    }
    
    func createPairingAndConnect() async throws -> WalletConnectURI? {
        try await WalletConnectModal.instance.connect(topic: nil)
    }
}
