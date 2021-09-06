
import Foundation

extension SessionType {
    struct ProposeParams: Codable, Equatable {
        let topic: String
        let relay: RelayProtocolOptions
        let proposer: Proposer
        let signal: Signal
        let permissions: Permissions
        let ttl: Int
    }
}
