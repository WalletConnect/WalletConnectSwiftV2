public struct ProposalNamespace: Equatable, Codable {
    public let chains: Set<Blockchain>
    public let methods: Set<String>
    public let events: Set<String>
    public let extensions: [Extension]?
    
    public struct Extension: Equatable, Codable {
        public let chains: Set<Blockchain>
        public let methods: Set<String>
        public let events: Set<String>
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
    }
}

enum Namespace {
    
    static func validate(_ namespaces: [String: ProposalNamespace]) throws {
        for (key, namespace) in namespaces {
            if namespace.chains.isEmpty {
                throw WalletConnectError.namespaceHasEmptyChains
            }
            for chain in namespace.chains {
                if key != chain.namespace {
                    throw WalletConnectError.invalidNamespace
                }
            }
            if let extensions = namespace.extensions {
                for ext in extensions {
                    if ext.chains.isEmpty {
                        throw WalletConnectError.namespaceHasEmptyChains
                    }
                }
            }
        }
    }
    
    static func validate(_ namespaces: [String: SessionNamespace]) throws {
        for (key, namespace) in namespaces {
            if namespace.accounts.isEmpty {
                throw WalletConnectError.invalidNamespace
            }
            for account in namespace.accounts {
                if key != account.namespace {
                    throw WalletConnectError.invalidNamespace
                }
            }
            if let extensions = namespace.extensions {
                for ext in extensions {
                    if ext.accounts.isEmpty {
                        throw WalletConnectError.invalidNamespace
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
                throw WalletConnectError.invalidNamespaceMatch
            }
            try proposedNamespace.chains.forEach { chain in
                if !approvedNamespace.accounts.contains(where: { $0.blockchain == chain }) {
                    throw WalletConnectError.invalidNamespaceMatch
                }
            }
            try proposedNamespace.methods.forEach {
                if !approvedNamespace.methods.contains($0) {
                    throw WalletConnectError.invalidNamespaceMatch
                }
            }
            try proposedNamespace.events.forEach {
                if !approvedNamespace.events.contains($0) {
                    throw WalletConnectError.invalidNamespaceMatch
                }
            }
        }
    }
}
