import WalletConnectPairing
import WalletConnectSign
import WalletConnectSigner
import WalletConnectIdentity
import Auth
import Combine
import WalletConnectNetworking
import Foundation

extension ModalSheet {
    final class Interactor {
        let projectId: String
        let metadata: AppMetadata
        let socketFactory: WebSocketFactory
        
        private var disposeBag = Set<AnyCancellable>()
        
        var signature: CurrentValueSubject<CacaoSignature?, Never> = .init(nil)
        
        lazy var sessionsPublisher: AnyPublisher<[Session], Never> = Sign.instance.sessionsPublisher
        
        init(projectId: String, metadata: AppMetadata, webSocketFactory: WebSocketFactory) {
            self.projectId = projectId
            self.metadata = metadata
            self.socketFactory = webSocketFactory
            
            Pair.configure(metadata: metadata)
            Networking.configure(projectId: projectId, socketFactory: socketFactory)
            
            sessionsPublisher.sink { sessions in
                Web3Modal.session = sessions.first
            }
            .store(in: &disposeBag)
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
}
