
import Foundation

enum JSONRPCResponseType {
    case requestAcknowledge
    case subscriptionAcknowledge(String)
}
