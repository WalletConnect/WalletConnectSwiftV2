
import Foundation
import WalletConnectNetworking

public protocol Paringable: AnyObject {
    var protocolMethod: ProtocolMethod { get set }
    var pairingRequestSubscriber: PairingRequestSubscriber! {get set}
    var pairingRequester: PairingRequester! {get set}
}
