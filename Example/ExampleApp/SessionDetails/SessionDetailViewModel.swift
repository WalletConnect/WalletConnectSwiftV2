import Foundation
import Combine
import WalletConnectAuth

@MainActor
final class SessionDetailViewModel: ObservableObject {
    private let session: Session
    private let client: Auth
    
    enum Fields {
        case accounts
        case methods
        case events
        case chain
    }
    
    @Published var namespaces: [String: SessionNamespace]
    
    init(session: Session, client: Auth) {
        self.session = session
        self.client = client
        self.namespaces = session.namespaces
    }
    
    var peerName: String {
        session.peer.name
    }
    var peerDescription: String {
        session.peer.description
    }
    var peerURL: String {
        session.peer.url
    }
    var peerIconURL: URL? {
        session.peer.icons.first.flatMap { URL(string: $0) }
    }
    var chains: [String] {
        namespaces.keys.sorted()
    }
    var requests: [Request] {
        client.getPendingRequests(topic: session.topic)
    }
    
    func remove(field: Fields, at indices: IndexSet = [], for chain: String) async {
        let backup = namespaces

        do {
            switch field {
            case .accounts: removeAccounts(at: indices, chain: chain)
            case .methods: removeMethods(at: indices, chain: chain)
            case .events: removeEvents(at: indices, chain: chain)
            case .chain: removeChain(chain)
            }
            
            try await client.update(
                topic: session.topic,
                namespaces: namespaces
            )
        }
        catch {
            namespaces = backup
            print("[RESPONDER] Namespaces update failed with: \(error.localizedDescription)")
        }
    }
    
    func ping() {
        client.ping(topic: session.topic) {  result in
            switch result {
            case .success:
                print("[RESPONDER] Received ping response")
            case .failure(let error):
                print("[RESPONDER] Ping failed with: \(error.localizedDescription)")
            }
        }
    }
    
    func namespace(for chain: String) -> SessionNamespaceViewModel? {
        namespaces[chain].map { SessionNamespaceViewModel(namespace: $0) }
    }
}

private extension SessionDetailViewModel {
    
    func removeAccounts(at offsets: IndexSet, chain: String) {
        guard let viewModel = namespace(for: chain) else { return }

        namespaces[chain] = SessionNamespace(
            accounts: Set(viewModel.accounts.removing(atOffsets: offsets)),
            namespace: viewModel.namespace
        )
    }
    
    func removeMethods(at offsets: IndexSet, chain: String) {
        guard let viewModel = namespace(for: chain) else { return }

        namespaces[chain] = SessionNamespace(
            methods: Set(viewModel.methods.removing(atOffsets: offsets)),
            namespace: viewModel.namespace
        )
    }
    
    func removeEvents(at offsets: IndexSet, chain: String) {
        guard let viewModel = namespace(for: chain) else { return }
        
        namespaces[chain] = SessionNamespace(
            events: Set(viewModel.events.removing(atOffsets: offsets)),
            namespace: viewModel.namespace
        )
    }
    
    func removeChain(_ chain: String) {
        namespaces.removeValue(forKey: chain)
    }
}

private extension Array {
    
    func removing(atOffsets offsets: IndexSet) -> Self {
        var array = self
        array.remove(atOffsets: offsets)
        return array
    }
}

private extension SessionNamespace {
    
    init(
        accounts: Set<Account>? = nil,
        methods: Set<String>? = nil,
        events: Set<String>? = nil,
        namespace: SessionNamespace
    ) {
        self.init(
            accounts: accounts ?? namespace.accounts,
            methods: methods ?? namespace.methods,
            events: events ?? namespace.events,
            extensions: namespace.extensions
        )
    }
}
