
import Foundation

extension PairingType {
    public struct Settled: Codable, SequenceSettled, Equatable {
        public let topic: String
        let relay: RelayProtocolOptions
        let `self`: Participant
        public let peer: Participant
        let permissions: Permissions
        let expiry: Int
        var state: State?
    }
}
