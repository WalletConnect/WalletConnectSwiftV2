// 

import Foundation

struct PairingProposal {
    let topic: String
    let relay: RelayProtocolOptions
    let proposer: PairingProposer
    let signal: PairingSignal
    let permissions: PairingProposedPermissions
    let ttl: Int
}

struct PairingProposer {
  let publicKey: String
  let controller: Bool
}

struct RelayProtocolOptions: Codable {
    let `protocol`: String
    let params: [String]?
}

struct PairingProposedPermissions {
    struct JSONRPC {
        let methods: [String]
    }
    let jsonrpc: JSONRPC
}
