import WalletConnectPairing
import WalletConnectSign
import Combine

protocol ModalSheetInteractor {
    func getListings() async throws -> [Listing]
    func connect() async throws -> WalletConnectURI
    
    var sessionSettlePublisher: AnyPublisher<Session, Never> { get }
}

final class DefaultModalSheetInteractor: ModalSheetInteractor {
    let projectId: String
    let metadata: AppMetadata
    let socketFactory: WebSocketFactory
    
    lazy var sessionSettlePublisher: AnyPublisher<Session, Never> = Sign.instance.sessionSettlePublisher
    
    init(projectId: String, metadata: AppMetadata, webSocketFactory: WebSocketFactory) {
        self.projectId = projectId
        self.metadata = metadata
        self.socketFactory = webSocketFactory
        
        Pair.configure(metadata: metadata)
        Networking.configure(projectId: projectId, socketFactory: socketFactory)
    }
    
    func getListings() async throws -> [Listing] {
        
        let httpClient = HTTPNetworkClient(host: "explorer-api.walletconnect.com")
        let response = try await httpClient.request(
            ListingsResponse.self,
            at: ExplorerAPI.getListings(projectId: projectId)
        )
    
        return response.listings.values.compactMap { $0 }
    }
    
    func connect() async throws -> WalletConnectURI {
        
        let uri = try await Pair.instance.create()
        
        let methods: Set<String> = ["eth_sendTransaction", "personal_sign", "eth_signTypedData"]
        let blockchains: Set<Blockchain> = [Blockchain("eip155:1")!]
        let namespaces: [String: ProposalNamespace] = [
            "eip155": ProposalNamespace(
                chains: blockchains,
                methods: methods,
                events: []
            )
        ]
        
        try await Sign.instance.connect(requiredNamespaces: namespaces, topic: uri.topic)
        
        return uri
    }
}
