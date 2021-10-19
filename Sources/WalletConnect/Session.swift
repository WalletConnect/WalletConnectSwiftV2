public struct Session {
    public let topic: String
    public let peer: AppMetadata? // TODO: Remove optional, there's always a peer
}

public struct SessionProposal {
    public let proposer: AppMetadata
    public let permissions: SessionPermissions
    
    // TODO: Refactor internal objects to manage only needed data
    internal let proposal: SessionType.Proposal
}

public struct SessionPermissions {
    public let blockchains: [String]
    public let methods: [String]
}
