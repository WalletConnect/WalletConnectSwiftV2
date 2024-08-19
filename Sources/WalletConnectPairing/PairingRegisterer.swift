import Foundation
import Combine

public protocol PairingRegisterer {
    func register<RequestParams: Codable>(
        method: ProtocolMethod
    ) -> AnyPublisher<RequestSubscriptionPayload<RequestParams>, Never>

    func setReceived(pairingTopic: String)
}
