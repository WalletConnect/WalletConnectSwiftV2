public struct Namespace: Codable, Equatable, Hashable {
    
    public let chains: Set<Blockchain>
    public let methods: Set<String>
    public let events: Set<String>
    
    public init(chains: Set<Blockchain>, methods: Set<String>, events: Set<String>) {
        self.chains = chains
        self.methods = methods
        self.events = events
    }
}

internal extension Namespace {
    
    static func validate(_ namespaces: Set<Namespace>) throws {
        for namespace in namespaces {
            guard !namespace.chains.isEmpty else {
                throw WalletConnectError.namespaceHasEmptyChains
            }
            for method in namespace.methods {
                if method.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    throw WalletConnectError.invalidMethod
                }
            }
            for event in namespace.events {
                if event.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    throw WalletConnectError.invalidEvent
                }
            }
        }
    }
}

public struct ProposalNamespace {
    public let chains: Set<Blockchain>
    public let methods: Set<String>
    public let events: Set<String>
    public let `extension`: [Extension]?
    
    public struct Extension {
        public let chains: Set<Blockchain>
        public let methods: Set<String>
        public let events: Set<String>
    }
}

public struct SessionNamespace {
    public let accounts: Set<Account>
    public let methods: Set<String>
    public let events: Set<String>
    public let `extension`: [Extension]?
    
    public struct Extension {
        public let chains: Set<Account>
        public let methods: Set<String>
        public let events: Set<String>
    }
}
