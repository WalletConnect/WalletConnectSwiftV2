import Foundation
/**
 A representation of an active pairing connection.
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

#if DEBUG
extension Pairing {
    static func stub(expiryDate: Date = Date(timeIntervalSinceNow: 10000), topic: String = String.generateTopic()) -> Pairing {
        Pairing(WCPairing.stub(expiryDate: expiryDate, topic: topic))
    }
}
#endif
