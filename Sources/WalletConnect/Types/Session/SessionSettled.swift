
import Foundation

extension SessionType {
    public struct Settled: Codable, SequenceSettled, Equatable {
        public let topic: String
        let relay: RelayProtocolOptions
        let `self`: Participant
        public let peer: Participant
        var permissions: Permissions
        let expiry: Int
        var state: State
        var isController: Bool {
            guard let controller = permissions.controller else {return false}
            return self.`self`.publicKey == controller.publicKey
        }
    }
}
