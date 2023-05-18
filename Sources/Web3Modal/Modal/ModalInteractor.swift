
import Foundation
import WalletConnectPairing
import WalletConnectSign
import Combine
import WalletConnectNetworking

extension ModalSheet {
    final class Interactor {
        var disposeBag = Set<AnyCancellable>()
        
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
            
            sessionsPublisher
                .receive(on: DispatchQueue.main)
                .sink { [weak self] sessions in
                    print(sessions)
                    
                    self?.personal_sign(session: sessions.first!)
                }
                .store(in: &disposeBag)
        }
        
        func personal_sign(session: Session) {
         
            let method = "personal_sign"
            let account = session.namespaces.first!.value.accounts.first!.absoluteString
            let requestParams =  AnyCodable(
                ["0x4d7920656d61696c206973206a6f686e40646f652e636f6d202d2031363533333933373535313531", account]
            )
            
            let request = Request(
                topic: session.topic,
                method: method,
                params: requestParams,
                chainId: Blockchain("eip155:1")!
            )
            
            Task {
                
                try? await Sign.instance.request(params: request)
            }
        }
        
        func getListings() async throws -> [Listing] {
            let listingResponse = try await ExplorerApi.live().getListings(projectId)
            return listingResponse.listings.values.compactMap { $0 }
        }
        
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

