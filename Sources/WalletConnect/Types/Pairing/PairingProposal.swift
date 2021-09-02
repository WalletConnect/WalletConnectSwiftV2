
import Foundation

struct PairingProposal: Codable {
    let topic: String
    let relay: RelayProtocolOptions
    let proposer: PairingProposer
    let signal: PairingSignal
    let permissions: PairingProposedPermissions
    let ttl: Int
}

struct PairingProposer: Codable {
    let publicKey: String
    let controller: Bool
}

struct PairingProposedPermissions: Codable {
    let jsonrpc: JSONRPC
}

struct PairingPermissions: Codable {
    let jsonrpc: JSONRPC
    let controller: Controller
}
