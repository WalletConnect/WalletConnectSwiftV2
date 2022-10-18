import Foundation
import WalletConnectNetworking
import Combine
import JSONRPC

public protocol PairingRegisterer {
    func register<RequestParams: Codable>(
        method: ProtocolMethod
    ) -> AnyPublisher<RequestSubscriptionPayload<RequestParams>, Never>

    func activate(pairingTopic: String)
    func validatePairingExistance(_ topic: String) throws
    func updateMetadata(_ topic: String, metadata: AppMetadata)
}
