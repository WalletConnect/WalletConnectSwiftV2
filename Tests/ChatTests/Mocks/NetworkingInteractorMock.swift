import Foundation
@testable import Chat
import Combine
import WalletConnectUtils
import WalletConnectRelay

class NetworkingInteractorMock: NetworkInteracting {

    var socketConnectionStatusPublisher: AnyPublisher<SocketConnectionStatus, Never> {
        socketConnectionStatusPublisherSubject.eraseToAnyPublisher()
    }
    let socketConnectionStatusPublisherSubject = PassthroughSubject<SocketConnectionStatus, Never>()

    let responsePublisherSubject = PassthroughSubject<ChatResponse, Never>()
    let requestPublisherSubject = PassthroughSubject<RequestSubscriptionPayload, Never>()

    var requestPublisher: AnyPublisher<RequestSubscriptionPayload, Never> {
        requestPublisherSubject.eraseToAnyPublisher()
    }

    var responsePublisher: AnyPublisher<ChatResponse, Never> {
        responsePublisherSubject.eraseToAnyPublisher()
    }

    func requestUnencrypted(_ request: JSONRPCRequest<ChatRequestParams>, topic: String) async throws {

    }

    func request(_ request: JSONRPCRequest<ChatRequestParams>, topic: String) async throws {

    }

    func respond(topic: String, response: JsonRpcResult, tag: Int) async throws {

    }

    func respondSuccess(payload: RequestSubscriptionPayload) async throws {

    }

    private(set) var subscriptions: [String] = []

    func subscribe(topic: String) async throws {
        subscriptions.append(topic)
    }

    func didSubscribe(to topic: String) -> Bool {
        subscriptions.contains { $0 == topic }
    }
}
