
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

struct Proposer: Codable, Equatable {
    let publicKey: String
    let metadata: AppMetadata
}
//?
struct BlockchainProposed: Codable, Equatable {
    // TODO - change for caip2 objects
    let chains: Set<String>
}
