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
