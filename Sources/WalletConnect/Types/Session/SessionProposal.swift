
import Foundation

struct SessionState: Codable, Equatable {
    var accounts: [String]
}

struct SessionProposal: Codable, Equatable {
    let relay: RelayProtocolOptions
    let proposer: Proposer
    let permissions: SessionPermissions
    let blockchainProposed: Blockchain
}

struct Proposer: Codable, Equatable {
    let publicKey: String
    let metadata: AppMetadata
}

struct Blockchain: Codable, Equatable {
    let chains: Set<String>
    let accounts: Set<Account>
}
