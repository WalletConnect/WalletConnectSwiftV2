import Foundation
/**
 A representation of a pairing connection.
 */
public struct Pairing {
    public let topic: String
    public let peer: AppMetadata?
    public let expiryDate: Date
    public let active: Bool

    init(_ pairing: WCPairing) {
        self.topic = pairing.topic
        self.peer = pairing.peerMetadata
        self.expiryDate = pairing.expiryDate
        self.active = pairing.active
    }
}
