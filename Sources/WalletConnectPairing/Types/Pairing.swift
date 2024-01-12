import Foundation
/**
 A representation of an active pairing connection.
 */
public struct Pairing {
    public let topic: String
    public let peer: AppMetadata?
    public let expiryDate: Date
    public let active: Bool

//    public init(topic: String, peer: AppMetadata?, expiryDate: Date) {
//        self.topic = topic
//        self.peer = peer
//        self.expiryDate = expiryDate
//    }

    init(_ pairing: WCPairing) {
        self.topic = pairing.topic
        self.peer = pairing.peerMetadata
        self.expiryDate = pairing.expiryDate
        self.active = pairing.active
    }
}
