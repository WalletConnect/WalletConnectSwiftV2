
import Foundation
import Combine
import WalletConnectNetworking
import JSONRPC

public protocol Pairingable: AnyObject {
    var protocolMethod: ProtocolMethod { get set }
    var requestPublisherSubject: PassthroughSubject<(topic: String, request: RPCRequest), Never> {get}
}
