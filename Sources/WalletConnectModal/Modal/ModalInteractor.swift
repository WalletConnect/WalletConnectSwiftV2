
import Combine
import Foundation

protocol ModalSheetInteractor {
    func getWallets(page: Int, entries: Int) async throws -> (Int, [Wallet])
    func createPairingAndConnect() async throws -> WalletConnectURI
    
    var sessionSettlePublisher: AnyPublisher<Session, Never> { get }
    var sessionRejectionPublisher: AnyPublisher<(Session.Proposal, Reason), Never> { get }
}

final class DefaultModalSheetInteractor: ModalSheetInteractor {
    lazy var sessionSettlePublisher: AnyPublisher<Session, Never> = WalletConnectModal.instance.sessionSettlePublisher
    lazy var sessionRejectionPublisher: AnyPublisher<(Session.Proposal, Reason), Never> = WalletConnectModal.instance.sessionRejectionPublisher
    
    func getWallets(page: Int, entries: Int) async throws -> (Int, [Wallet]) {
        let httpClient = HTTPNetworkClient(host: "api.web3modal.org")
        let response = try await httpClient.request(
            GetWalletsResponse.self,
            at: Web3ModalAPI.getWallets(
                params: Web3ModalAPI.GetWalletsParams(
                    page: page,
                    entries: entries,
                    search: nil,
                    projectId: WalletConnectModal.config.projectId,
                    metadata: WalletConnectModal.config.metadata,
                    recommendedIds: WalletConnectModal.config.recommendedWalletIds,
                    excludedIds: WalletConnectModal.config.excludedWalletIds
                )
            )
        )
    
        return (response.count, response.data.compactMap { $0 })
    }
    
    func createPairingAndConnect() async throws -> WalletConnectURI {
        try await WalletConnectModal.instance.connect()
    }
}
