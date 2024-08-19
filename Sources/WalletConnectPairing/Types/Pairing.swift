import Foundation
/**
 A representation of an active pairing connection.
 */
public struct Pairing {
    public let topic: String
    public let expiryDate: Date

    init(_ pairing: WCPairing) {
        self.topic = pairing.topic
        self.expiryDate = pairing.expiryDate
    }
}

#if DEBUG
extension Pairing {
    static func stub(expiryDate: Date = Date(timeIntervalSinceNow: 10000), topic: String = String.generateTopic()) -> Pairing {
        Pairing(WCPairing.stub(expiryDate: expiryDate, topic: topic))
    }
}
#endif
