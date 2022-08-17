import Foundation
import Combine
@testable import Auth
import JSONRPC
import WalletConnectKMS

struct NetworkingInteractorMock: NetworkInteracting {

    var responsePublisher: AnyPublisher<ResponseSubscriptionPayload, Never> {
        responsePublisherSubject.eraseToAnyPublisher()
    }
    private let responsePublisherSubject = PassthroughSubject<ResponseSubscriptionPayload, Never>()

    let requestPublisherSubject = PassthroughSubject<RequestSubscriptionPayload, Never>()
    var requestPublisher: AnyPublisher<RequestSubscriptionPayload, Never> {
        requestPublisherSubject.eraseToAnyPublisher()
    }

    func subscribe(topic: String) async throws {

    }

    func unsubscribe(topic: String) {

    }

    func request(_ request: RPCRequest, topic: String, tag: Int, envelopeType: Envelope.EnvelopeType) async throws {

    }

    func respond(topic: String, response: RPCResponse, tag: Int, envelopeType: Envelope.EnvelopeType) async throws {

    }

    func requestNetworkAck(_ request: RPCRequest, topic: String, tag: Int) async throws {

    }

}
