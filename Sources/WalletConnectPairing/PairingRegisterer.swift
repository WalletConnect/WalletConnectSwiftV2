import Foundation
import WalletConnectNetworking
import Combine
import JSONRPC

public protocol PairingRegisterer {
    func register(method: ProtocolMethod) -> AnyPublisher<(topic: String, request: RPCRequest), Never>
}
