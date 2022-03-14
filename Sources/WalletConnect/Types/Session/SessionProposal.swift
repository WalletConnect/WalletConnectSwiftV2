
import Foundation

struct SessionState: Codable, Equatable {
    var accounts: [String]
}

struct SessionProposal: Codable, Equatable {
    let relay: RelayProtocolOptions
    let proposer: Participant
    let permissions: SessionPermissions
    let blockchainProposed: Blockchain
}


struct Blockchain: Codable, Equatable {
    var chains: Set<String>
    var accounts: Set<Account>
}
