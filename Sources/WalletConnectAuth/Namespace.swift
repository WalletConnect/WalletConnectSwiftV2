
public struct ProposalNamespace: Equatable, Codable {
    
    public let chains: Set<Blockchain>
    public let methods: Set<String>
    public let events: Set<String>
    public let `extension`: [Extension]?
    
    public struct Extension: Equatable, Codable {
        public let chains: Set<Blockchain>
        public let methods: Set<String>?
        public let events: Set<String>?
        
        public init(chains: Set<Blockchain>, methods: Set<String>?, events: Set<String>?) {
            self.chains = chains
            self.methods = methods
            self.events = events
        }
    }
    
    public init(chains: Set<Blockchain>, methods: Set<String>, events: Set<String>, extension: [ProposalNamespace.Extension]?) {
        self.chains = chains
        self.methods = methods
        self.events = events
        self.`extension` = `extension`
    }
}

public struct SessionNamespace: Equatable, Codable {
    
    public let accounts: Set<Account>
    public let methods: Set<String>
    public let events: Set<String>
    public let `extension`: [Extension]?
    
    public struct Extension: Equatable, Codable {
        public let accounts: Set<Account>
        public let methods: Set<String>?
        public let events: Set<String>?
        
        public init(accounts: Set<Account>, methods: Set<String>?, events: Set<String>?) {
            self.accounts = accounts
            self.methods = methods
            self.events = events
        }
    }
    
    public init(accounts: Set<Account>, methods: Set<String>, events: Set<String>, extension: [SessionNamespace.Extension]?) {
        self.accounts = accounts
        self.methods = methods
        self.events = events
        self.`extension` = `extension`
    }
}

enum Validator {
    
    static func validate(_ namespaces: [String: ProposalNamespace]) throws {
        // TODO
    }
    
    static func validate(_ namespaces: [String: SessionNamespace]) throws {
        // TODO
    }
}
