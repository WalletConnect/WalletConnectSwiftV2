import Foundation
import Combine
@testable import Auth
import JSONRPC
import WalletConnectKMS

struct NetworkingInteractorMock: NetworkInteracting {

    let requestPublisherSubject = PassthroughSubject<RequestSubscriptionPayload, Never>()
    var requestPublisher: AnyPublisher<RequestSubscriptionPayload, Never> {
        requestPublisherSubject.eraseToAnyPublisher()
    }

    func subscribe(topic: String) async throws {

    }

    func request(_ request: RPCRequest, topic: String, tag: Int, envelopeType: Envelope.EnvelopeType) async throws {

    }

    func respond(topic: String, response: RPCResponse, tag: Int, envelopeType: Envelope.EnvelopeType) async throws {

    }

}
