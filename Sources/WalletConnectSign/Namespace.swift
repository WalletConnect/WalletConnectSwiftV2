public enum AutoNamespacesError: Error {
    case requiredChainsNotSatisfied
    case requiredAccountsNotSatisfied
    case requiredMethodsNotSatisfied
    case requiredEventsNotSatisfied
}

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
        var requiredNamespaces = [String: ProposalNamespace]()
        proposalNamespaces.forEach {
            let caip2Namespace = $0.key
            let proposalNamespace = $0.value

            if proposalNamespace.chains != nil {
                requiredNamespaces[caip2Namespace] = proposalNamespace
            } else {
                if let network = $0.key.components(separatedBy: ":").first {
                    let proposalNamespace = ProposalNamespace(chains: [Blockchain($0.key)!], methods: proposalNamespace.methods, events: proposalNamespace.events)
                    if requiredNamespaces[network] == nil {
                        requiredNamespaces[network] = proposalNamespace
                    } else {
                        let unionChains = requiredNamespaces[network]?.chains!.union(proposalNamespace.chains ?? [])
                        let unionMethods = requiredNamespaces[network]?.methods.union(proposalNamespace.methods)
                        let unionEvents = requiredNamespaces[network]?.events.union(proposalNamespace.events)
                        
                        let namespace = ProposalNamespace(chains: unionChains, methods: unionMethods ?? [], events: unionEvents ?? [])
                        requiredNamespaces[network] = namespace
                    }
                }
            }
        }
        
        for (key, proposedNamespace) in requiredNamespaces {
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
                        throw WalletConnectError.unsupportedNamespace(.unsupportedAccounts)
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

public enum AutoNamespaces {
    /// For a wallet to build session proposal structure by provided supported chains, methods, events & accounts.
    /// - Parameters:
    ///   - proposalId: Session Proposal id
    ///   - namespaces: namespaces for given session, needs to contain at least required namespaces proposed by dApp.
    public static func build(
        sessionProposal: Session.Proposal,
        chains: [Blockchain],
        methods: [String],
        events: [String],
        accounts: [Account]
    ) throws -> [String: SessionNamespace] {
        var sessionNamespaces = [String: SessionNamespace]()

        try sessionProposal.requiredNamespaces.forEach {
            let caip2Namespace = $0.key
            let proposalNamespace = $0.value

            if let proposalChains = proposalNamespace.chains {
                let sessionChains = Set(proposalChains).intersection(Set(chains))
                guard !sessionChains.isEmpty else {
                    throw AutoNamespacesError.requiredChainsNotSatisfied
                }
                
                let sessionMethods = Set(proposalNamespace.methods).intersection(Set(methods))
                guard proposalNamespace.methods.isSubset(of: Set(methods)) else {
                    throw AutoNamespacesError.requiredMethodsNotSatisfied
                }
                
                let sessionEvents = Set(proposalNamespace.events).intersection(Set(events))
                guard proposalNamespace.events.isSubset(of: Set(events)) else {
                    throw AutoNamespacesError.requiredEventsNotSatisfied
                }
                
                let availableAccountsBlockchains = accounts.map { $0.blockchain }
                guard !sessionChains.intersection(Set(availableAccountsBlockchains)).isEmpty else {
                    throw AutoNamespacesError.requiredAccountsNotSatisfied
                }

                let sessionNamespace = SessionNamespace(
                    chains: sessionChains,
                    accounts: Set(accounts).filter { sessionChains.contains($0.blockchain) },
                    methods: sessionMethods,
                    events: sessionEvents
                )
                
                if sessionNamespaces[caip2Namespace] == nil {
                    sessionNamespaces[caip2Namespace] = sessionNamespace
                } else {
                    let unionChains = (sessionNamespaces[caip2Namespace]?.chains ?? []).union(sessionNamespace.chains ?? [])
                    sessionNamespaces[caip2Namespace]?.chains = unionChains
                    let unionAccounts = sessionNamespaces[caip2Namespace]?.accounts.union(sessionNamespace.accounts)
                    sessionNamespaces[caip2Namespace]?.accounts = unionAccounts ?? []
                    let unionMethods = sessionNamespaces[caip2Namespace]?.methods.union(sessionNamespace.methods)
                    sessionNamespaces[caip2Namespace]?.methods = unionMethods ?? []
                    let unionEvents = sessionNamespaces[caip2Namespace]?.events.union(sessionNamespace.events)
                    sessionNamespaces[caip2Namespace]?.events = unionEvents ?? []
                }
            } else {
                if let network = $0.key.components(separatedBy: ":").first,
                   let chain = $0.key.components(separatedBy: ":").last
                {
                    let sessionChains = Set([Blockchain(namespace: network, reference: chain)]).intersection(Set(chains))
                    guard !sessionChains.isEmpty else {
                        throw AutoNamespacesError.requiredChainsNotSatisfied
                    }
                    
                    let sessionMethods = Set(proposalNamespace.methods).intersection(Set(methods))
                    guard proposalNamespace.methods.isSubset(of: Set(methods)) else {
                        throw AutoNamespacesError.requiredMethodsNotSatisfied
                    }
                    
                    let sessionEvents = Set(proposalNamespace.events).intersection(Set(events))
                    guard proposalNamespace.events.isSubset(of: Set(events)) else {
                        throw AutoNamespacesError.requiredEventsNotSatisfied
                    }
                    
                    let availableAccountsBlockchains = accounts.map { $0.blockchain }
                    guard !sessionChains.intersection(Set(availableAccountsBlockchains)).isEmpty else {
                        throw AutoNamespacesError.requiredAccountsNotSatisfied
                    }

                    let sessionNamespace = SessionNamespace(
                        chains: Set([Blockchain(namespace: network, reference: chain)!]),
                        accounts: Set(accounts).filter { $0.blockchain == Blockchain(namespace: network, reference: chain)! },
                        methods: sessionMethods,
                        events: sessionEvents
                    )
                    
                    if sessionNamespaces[network] == nil {
                        sessionNamespaces[network] = sessionNamespace
                    } else {
                        let unionChains = (sessionNamespaces[network]?.chains ?? []).union(sessionNamespace.chains ?? [])
                        sessionNamespaces[network]?.chains = unionChains
                        let unionAccounts = sessionNamespaces[network]?.accounts.union(sessionNamespace.accounts)
                        sessionNamespaces[network]?.accounts = unionAccounts ?? []
                        let unionMethods = sessionNamespaces[network]?.methods.union(sessionNamespace.methods)
                        sessionNamespaces[network]?.methods = unionMethods ?? []
                        let unionEvents = sessionNamespaces[network]?.events.union(sessionNamespace.events)
                        sessionNamespaces[network]?.events = unionEvents ?? []
                    }
                }
            }
        }
        
        sessionProposal.optionalNamespaces?.forEach {
            let caip2Namespace = $0.key
            let proposalNamespace = $0.value

            if let proposalChains = proposalNamespace.chains {
                let sessionChains = Set(proposalChains).intersection(Set(chains))
                guard !sessionChains.isEmpty else {
                    return
                }
                
                let sessionMethods = Set(proposalNamespace.methods).intersection(Set(methods))
                guard !sessionMethods.isEmpty else {
                    return
                }
                
                let sessionEvents = Set(proposalNamespace.events).intersection(Set(events))
                guard !sessionEvents.isEmpty else {
                    return
                }

                let sessionNamespace = SessionNamespace(
                    chains: sessionChains,
                    accounts: Set(accounts).filter { sessionChains.contains($0.blockchain) },
                    methods: sessionMethods,
                    events: sessionEvents
                )
                
                if sessionNamespaces[caip2Namespace] == nil {
                    sessionNamespaces[caip2Namespace] = sessionNamespace
                } else {
                    let unionChains = (sessionNamespaces[caip2Namespace]?.chains ?? []).union(sessionNamespace.chains ?? [])
                    sessionNamespaces[caip2Namespace]?.chains = unionChains
                    let unionAccounts = sessionNamespaces[caip2Namespace]?.accounts.union(sessionNamespace.accounts)
                    sessionNamespaces[caip2Namespace]?.accounts = unionAccounts ?? []
                    let unionMethods = sessionNamespaces[caip2Namespace]?.methods.union(sessionNamespace.methods)
                    sessionNamespaces[caip2Namespace]?.methods = unionMethods ?? []
                    let unionEvents = sessionNamespaces[caip2Namespace]?.events.union(sessionNamespace.events)
                    sessionNamespaces[caip2Namespace]?.events = unionEvents ?? []
                }
            } else {
                if let network = $0.key.components(separatedBy: ":").first,
                   let chain = $0.key.components(separatedBy: ":").last
                {
                    let sessionChains = Set([Blockchain(namespace: network, reference: chain)]).intersection(Set(chains))
                    guard !sessionChains.isEmpty else {
                        return
                    }
                    
                    let sessionMethods = Set(proposalNamespace.methods).intersection(Set(methods))
                    guard !sessionMethods.isEmpty else {
                        return
                    }
                    
                    let sessionEvents = Set(proposalNamespace.events).intersection(Set(events))
                    guard !sessionEvents.isEmpty else {
                        return
                    }
                    
                    let sessionNamespace = SessionNamespace(
                        chains: Set([Blockchain(namespace: network, reference: chain)!]),
                        accounts: Set(accounts).filter { $0.blockchain == Blockchain(namespace: network, reference: chain)! },
                        methods: sessionMethods,
                        events: sessionEvents
                    )
                    
                    if sessionNamespaces[network] == nil {
                        sessionNamespaces[network] = sessionNamespace
                    } else {
                        let unionChains = (sessionNamespaces[network]?.chains ?? []).union(sessionNamespace.chains ?? [])
                        sessionNamespaces[network]?.chains = unionChains
                        let unionAccounts = sessionNamespaces[network]?.accounts.union(sessionNamespace.accounts)
                        sessionNamespaces[network]?.accounts = unionAccounts ?? []
                        let unionMethods = sessionNamespaces[network]?.methods.union(sessionNamespace.methods)
                        sessionNamespaces[network]?.methods = unionMethods ?? []
                        let unionEvents = sessionNamespaces[network]?.events.union(sessionNamespace.events)
                        sessionNamespaces[network]?.events = unionEvents ?? []
                    }
                }
            }
        }
        
        return sessionNamespaces
    }
}
