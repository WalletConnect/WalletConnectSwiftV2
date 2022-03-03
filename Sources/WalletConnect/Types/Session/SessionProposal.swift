
import Foundation

struct SessionState: Codable, Equatable {
    var accounts: [String]
}

struct SessionProposal: Codable, Equatable {
    let relay: RelayProtocolOptions
    let proposer: Proposer
    let permissions: SessionPermissions
    let blockchainProposed: BlockchainProposed
}

// FIXME: This struct is redundant with Participant
struct Proposer: Codable, Equatable {
    let publicKey: String
    let metadata: AppMetadata
}
//?
struct BlockchainProposed: Codable, Equatable {
    //TODO - auth type not specified yet
    let auth: String? = nil
    // TODO - change for caip2 objects
    let chains: Set<String>
}
