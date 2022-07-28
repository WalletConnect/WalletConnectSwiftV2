import Foundation
import WalletConnectUtils
/**
 A representation of an active pairing connection.
 */
public struct Pairing {
    public let topic: String
    public let peer: AppMetadata?
    public let expiryDate: Date
}
