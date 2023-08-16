import Foundation
import WalletConnectPairing
import Combine
import WalletConnectNetworking

public class PairingRegistererMock<RequestParams>: PairingRegisterer where RequestParams: Codable {
    public let subject = PassthroughSubject<RequestSubscriptionPayload<RequestParams>, Never>()

    public var isActivateCalled: Bool = false

    public func register<RequestParams>(method: ProtocolMethod) -> AnyPublisher<RequestSubscriptionPayload<RequestParams>, Never> where RequestParams: Decodable, RequestParams: Encodable {
        subject.eraseToAnyPublisher() as! AnyPublisher<RequestSubscriptionPayload<RequestParams>, Never>
    }

    public func activate(pairingTopic: String, peerMetadata: WalletConnectPairing.AppMetadata?) {
        isActivateCalled = true
    }

    public func validatePairingExistance(_ topic: String) throws {

    }
    
    public func setReceived(pairingTopic: String) {
        
    }
}
