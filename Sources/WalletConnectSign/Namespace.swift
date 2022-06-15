import WalletConnectUtils

public struct ProposalNamespace: Equatable, Codable {
    
    public let chains: Set<Blockchain>
    public let methods: Set<String>
    public let events: Set<String>
    public let extensions: [Extension]?
    
    public struct Extension: Equatable, Codable {
        public let chains: Set<Blockchain>
        public let methods: Set<String>
        public let events: Set<String>
        
        public init(chains: Set<Blockchain>, methods: Set<String>, events: Set<String>) {
            self.chains = chains
            self.methods = methods
            self.events = events
        }
    }
    
    public init(chains: Set<Blockchain>, methods: Set<String>, events: Set<String>, extensions: [ProposalNamespace.Extension]? = nil) {
        self.chains = chains
        self.methods = methods
        self.events = events
        self.extensions = extensions
    }
}

public struct SessionNamespace: Equatable, Codable {
    
    public let accounts: Set<Account>
    public let methods: Set<String>
    public let events: Set<String>
    public let extensions: [Extension]?
    
    public struct Extension: Equatable, Codable {
        public let accounts: Set<Account>
        public let methods: Set<String>
        public let events: Set<String>
        
        public init(accounts: Set<Account>, methods: Set<String>, events: Set<String>) {
            self.accounts = accounts
            self.methods = methods
            self.events = events
        }
    }
    
    public init(accounts: Set<Account>, methods: Set<String>, events: Set<String>, extensions: [SessionNamespace.Extension]? = nil) {
        self.accounts = accounts
        self.methods = methods
        self.events = events
        self.extensions = extensions
    }
}

enum Namespace {
    
    static func validate(_ namespaces: [String: ProposalNamespace]) throws {
        for (key, namespace) in namespaces {
            if namespace.chains.isEmpty {
                throw WalletConnectError.unsupportedNamespace(.unsupportedChains)
            }
            for chain in namespace.chains {
                if key != chain.namespace {
                    throw WalletConnectError.unsupportedNamespace(.unsupportedChains)
                }
            }
            if let extensions = namespace.extensions {
                for ext in extensions {
                    if ext.chains.isEmpty {
                        throw WalletConnectError.unsupportedNamespace(.unsupportedChains)
                    }
                }
            }
        }
    }
    
    static func validate(_ namespaces: [String: SessionNamespace]) throws {
        for (key, namespace) in namespaces {
            if namespace.accounts.isEmpty {
                throw WalletConnectError.unsupportedNamespace(.unsupportedAccounts)
            }
            for account in namespace.accounts {
                if key != account.namespace {
                    throw WalletConnectError.unsupportedNamespace(.unsupportedAccounts)
                }
            }
            if let extensions = namespace.extensions {
                for ext in extensions {
                    if ext.accounts.isEmpty {
                        throw WalletConnectError.unsupportedNamespace(.unsupportedAccounts)
                    }
                }
            }
        }
    }
    
    static func validateApproved(
        _ sessionNamespaces: [String: SessionNamespace],
        against proposalNamespaces: [String: ProposalNamespace]
    ) throws {
        for (key, proposedNamespace) in proposalNamespaces {
            guard let approvedNamespace = sessionNamespaces[key] else {
                throw WalletConnectError.unsupportedNamespace(.unsupportedNamespaceKey)
            }
            try proposedNamespace.chains.forEach { chain in
                if !approvedNamespace.accounts.contains(where: { $0.blockchain == chain }) {
                    throw WalletConnectError.unsupportedNamespace(.unsupportedChains)
                }
            }
            try proposedNamespace.methods.forEach {
                if !approvedNamespace.methods.contains($0) {
                    throw WalletConnectError.unsupportedNamespace(.unsupportedMethods)
                }
            }
            try proposedNamespace.events.forEach {
                if !approvedNamespace.events.contains($0) {
                    throw WalletConnectError.unsupportedNamespace(.unsupportedEvents)
                }
            }
        }
    }
}
