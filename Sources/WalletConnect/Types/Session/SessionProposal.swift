
import Foundation

struct SessionProposal: Codable {
    let topic: String
    let relay: RelayProtocolOptions
    let proposer: SessionProposer
    let signal: SessionSignal
    let permissions: SessionProposedPermissions
    let ttl: Int
}

struct SessionProposer: Codable {
    let publicKey: String
    let controller: Bool
    let metadata: AppMetadata
}

struct SessionProposedPermissions: Codable {
    let blockchain: Blockchain
    let jsonrpc: JSONRPC
    let notifications: Notifications
}

struct Blockchain: Codable {
    let chains: [String]
}
struct JSONRPC: Codable {
    let methods: [String]
}

struct Notifications: Codable {
    let types: [String]
}

struct SessionPermissions: Codable {
    let blockchain: Blockchain
    let jsonrpc: JSONRPC
    let notifications: Notifications
    let controller: Controller
}
