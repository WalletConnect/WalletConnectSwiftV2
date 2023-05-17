import WalletConnectPairing
import WalletConnectSign
import Combine
import WalletConnectNetworking

extension ModalSheet {
    final class Interactor {
        let projectId: String
        let metadata: AppMetadata
        let socketFactory: WebSocketFactory
        
        lazy var sessionsPublisher: AnyPublisher<[Session], Never> = Sign.instance.sessionsPublisher
        
        init(projectId: String, metadata: AppMetadata, webSocketFactory: WebSocketFactory) {
            self.projectId = projectId
            self.metadata = metadata
            self.socketFactory = webSocketFactory
            
            Pair.configure(metadata: metadata)
            Networking.configure(projectId: projectId, socketFactory: socketFactory)
        }
        
//        func getListings() async throws -> [Listing] {
//            let listingResponse = try await ExplorerApi.live().getMobileListings(projectId)
//            return listingResponse.listings.values.compactMap { $0 }
//        }
        
        func connect() async throws -> WalletConnectURI {
            
            let uri = try await Pair.instance.create()
            
            let methods: Set<String> = ["eth_sendTransaction", "personal_sign", "eth_signTypedData"]
            let blockchains: Set<Blockchain> = [Blockchain("eip155:1")!, Blockchain("eip155:137")!]
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
}
