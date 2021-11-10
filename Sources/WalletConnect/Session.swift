public struct Session {
    public let topic: String
    public let peer: AppMetadata? // TODO: Remove optional, there's always a peer
}

public struct SessionProposal {
    public let proposer: AppMetadata
    public let permissions: SessionPermissions

    public var topic: String {
        return proposal.topic
    }
    // TODO: Refactor internal objects to manage only needed data
    internal let proposal: SessionType.Proposal
}

public struct SessionPermissions: Equatable {
    public let blockchains: Set<String>
    public let methods: Set<String>
    public init(blockchains: Set<String>, methods: Set<String>) {
        self.blockchains = blockchains
        self.methods = methods
    }
}
