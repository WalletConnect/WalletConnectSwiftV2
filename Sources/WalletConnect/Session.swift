public struct Session {
    public let topic: String
    public let peer: AppMetadata
    public let permissions: Permissions
}

//public struct SessionProposal {
//    public let proposer: AppMetadata
//    public let permissions: SessionPermissions
//
//    // TODO: Refactor internal objects to manage only needed data
//    internal let proposal: SessionProposal
//}

extension Session {
    
    public struct Proposal {
        public let proposer: AppMetadata
        public let permissions: Permissions
        
        // TODO: Refactor internal objects to manage only needed data
        internal let proposal: SessionProposal
    }
    
    public struct Permissions: Equatable {
        public let blockchains: Set<String>
        public let methods: Set<String>
        public init(blockchains: Set<String>, methods: Set<String>) {
            self.blockchains = blockchains
            self.methods = methods
        }
    }

}

//public struct SessionPermissions: Equatable {
//    public let blockchains: Set<String>
//    public let methods: Set<String>
//    public init(blockchains: Set<String>, methods: Set<String>) {
//        self.blockchains = blockchains
//        self.methods = methods
//    }
//}
