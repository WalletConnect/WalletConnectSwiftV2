import Foundation
import WalletConnectPairing
import Combine
import WalletConnectNetworking

public class PairingRegistererMock<RequestParams>: PairingRegisterer where RequestParams: Codable {
    public let subject = PassthroughSubject<RequestSubscriptionPayload<RequestParams>, Never>()

    public var isReceivedCalled: Bool = false

    public func register<RequestParams>(method: ProtocolMethod) -> AnyPublisher<RequestSubscriptionPayload<RequestParams>, Never> where RequestParams: Decodable, RequestParams: Encodable {
        subject.eraseToAnyPublisher() as! AnyPublisher<RequestSubscriptionPayload<RequestParams>, Never>
    }
    
    public func setReceived(pairingTopic: String) {
        isReceivedCalled = true
    }
}
