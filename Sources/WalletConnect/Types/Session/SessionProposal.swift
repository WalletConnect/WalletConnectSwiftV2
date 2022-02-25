
import Foundation

struct SessionState: Codable, Equatable {
    var accounts: [String]
}

struct SessionProposal: Codable, Equatable {
    //todo - remove topic
    let topic: String
    let relay: RelayProtocolOptions
    let proposer: Proposer
    let permissions: SessionPermissions
    let blockchainProposed: BlockchainProposed
    let ttl: Int
}

struct Proposer: Codable, Equatable {
    let publicKey: String
    let controller: Bool
    let metadata: AppMetadata
}
//?
struct BlockchainProposed: Codable, Equatable {
    //TODO - auth type not specified yet
    let auth: String? = nil
    // TODO - change for caip2 objects
    let chains: Set<String>
}
