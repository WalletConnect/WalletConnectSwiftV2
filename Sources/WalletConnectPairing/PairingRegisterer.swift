import Foundation
import WalletConnectNetworking
import Combine
import JSONRPC

public protocol PairingRegisterer {
    func register<RequestParams>(method: ProtocolMethod) -> AnyPublisher<RequestSubscriptionPayload<RequestParams>, Never> where RequestParams : Codable
}
