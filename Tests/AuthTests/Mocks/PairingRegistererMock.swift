import Foundation
import WalletConnectPairing
import Combine
import WalletConnectNetworking

struct PairingRegistererMock: PairingRegisterer {
    func register<RequestParams>(method: ProtocolMethod) -> AnyPublisher<RequestSubscriptionPayload<RequestParams>, Never> where RequestParams : Decodable, RequestParams : Encodable {
        fatalError()
    }
}
