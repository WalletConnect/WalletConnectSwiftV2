import Foundation
import WalletConnectPairing
import Combine
import WalletConnectNetworking

struct PairingRegistererMock<RequestParams>: PairingRegisterer where RequestParams : Codable {
    let subject = PassthroughSubject<RequestSubscriptionPayload<RequestParams>, Never>()

    func register<RequestParams>(method: ProtocolMethod) -> AnyPublisher<RequestSubscriptionPayload<RequestParams>, Never> where RequestParams : Decodable, RequestParams : Encodable {
        subject.eraseToAnyPublisher() as! AnyPublisher<RequestSubscriptionPayload<RequestParams>, Never>
    }
}
