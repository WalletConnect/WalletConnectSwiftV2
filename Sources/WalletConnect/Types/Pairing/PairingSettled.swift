
import Foundation

extension PairingType {
    public struct Settled: Codable, SequenceSettled, Equatable {
        enum SettledStatus: String, Equatable, Codable {
            case preSettled = "preSettled"
            case acknowledged = "acknowledged"
        }
        public let topic: String
        let relay: RelayProtocolOptions
        let `self`: Participant
        public let peer: Participant
        let permissions: Permissions
        let expiry: Int
        var state: State?

        public var metadata: AppMetadata? {
            return state?.metadata
        }
    }
}
