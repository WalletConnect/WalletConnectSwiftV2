
import Foundation

extension SessionType {
    public struct Settled: Codable, SequenceSettled, Equatable {
        public let topic: String
        let relay: RelayProtocolOptions
        let `self`: Participant
        public let peer: Participant
        let permissions: Permissions
        let expiry: Int
        let state: State
    }
}
