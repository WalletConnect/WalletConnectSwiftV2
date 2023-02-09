public struct ProposalNamespace: Equatable, Codable {

    public let chains: Set<Blockchain>?
    public let methods: Set<String>
    public let events: Set<String>

    public init(chains: Set<Blockchain>? = nil, methods: Set<String>, events: Set<String>) {
        self.chains = chains
        self.methods = methods
        self.events = events
    }
}

public struct SessionNamespace: Equatable, Codable {
    public var chains: Set<Blockchain>?
    public var accounts: Set<Account>
    public var methods: Set<String>
    public var events: Set<String>

    public init(chains: Set<Blockchain>? = nil, accounts: Set<Account>, methods: Set<String>, events: Set<String>) {
        self.chains = chains
        self.accounts = accounts
        self.methods = methods
        self.events = events
    }

    static func accountsAreCompliant(_ accounts: Set<Account>, toChains chains: Set<Blockchain>) -> Bool {
        for chain in chains {
            guard accounts.contains(where: { $0.blockchain == chain }) else {
                return false
            }
        }
        return true
    }
}

enum Namespace {

    static func validate(_ namespaces: [String: ProposalNamespace]) throws {
        for (key, namespace) in namespaces {
            let caip2Namespace = key.components(separatedBy: ":")
            
            if caip2Namespace.count > 1 {
                if let chain = caip2Namespace.last, !chain.isEmpty, namespace.chains != nil {
                    throw WalletConnectError.unsupportedNamespace(.unsupportedChains)
                }
            } else {
                guard let chains = namespace.chains, !chains.isEmpty else {
                    throw WalletConnectError.unsupportedNamespace(.unsupportedChains)
                }
                for chain in chains {
                    if key != chain.namespace {
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
                if key.components(separatedBy: ":").count > 1 {
                    if key != account.namespace + ":\(account.reference)" {
                        throw WalletConnectError.unsupportedNamespace(.unsupportedAccounts)
                    }
                } else if key != account.namespace {
                    throw WalletConnectError.unsupportedNamespace(.unsupportedAccounts)
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
            if let chains = proposedNamespace.chains {
                try chains.forEach { chain in
                    if !approvedNamespace.accounts.contains(where: { $0.blockchain == chain }) {
                        throw WalletConnectError.unsupportedNamespace(.unsupportedChains)
                    }
                }
            } else {
                if !approvedNamespace.accounts.contains(where: { $0.blockchain == Blockchain(key) }) {
                    throw WalletConnectError.unsupportedNamespace(.unsupportedChains)
                }
            }
        }
    }
}

enum SessionProperties {
    static func validate(_ sessionProperties: [String: String]) throws {
        if sessionProperties.isEmpty {
            throw WalletConnectError.emptySessionProperties
        }
    }
}
