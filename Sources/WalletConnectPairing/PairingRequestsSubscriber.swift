import Foundation
import Combine
import WalletConnectUtils
import WalletConnectNetworking
import JSONRPC

public class PairingRequestsSubscriber {
    private let networkingInteractor: NetworkInteracting
    private let pairingStorage: PairingStorage
    private var publishers = Set<AnyCancellable>()
    private var protocolMethods = SetStore<String>()
    private let logger: ConsoleLogging

    init(networkingInteractor: NetworkInteracting,
         pairingStorage: PairingStorage,
         logger: ConsoleLogging) {
        self.networkingInteractor = networkingInteractor
        self.pairingStorage = pairingStorage
        self.logger = logger
        handleUnregisteredRequests()
    }

    func subscribeForRequest<RequestParams: Codable>(_ protocolMethod: ProtocolMethod) -> AnyPublisher<RequestSubscriptionPayload<RequestParams>, Never> {

        Task(priority: .high) { await protocolMethods.insert(protocolMethod.method) }

        let publisherSubject = PassthroughSubject<RequestSubscriptionPayload<RequestParams>, Never>()

        networkingInteractor.requestSubscription(on: protocolMethod).sink { (payload: RequestSubscriptionPayload<RequestParams>) in
            publisherSubject.send(payload)
        }.store(in: &publishers)

        return publisherSubject.eraseToAnyPublisher()
    }

    func handleUnregisteredRequests() {
        Task(priority: .high) { [unowned self] in
            await protocolMethods.insert(PairingDeleteProtocolMethod().method)
            await protocolMethods.insert(PairingPingProtocolMethod().method)
        }
        networkingInteractor.requestPublisher
            .asyncFilter { [unowned self] in await !protocolMethods.contains($0.request.method)}
            .sink { [unowned self] topic, request in
                Task(priority: .high) {
                    let protocolMethod = UnsupportedProtocolMethod(method: request.method)
                    logger.debug("PairingRequestsSubscriber: responding unregistered request method")
                    try await networkingInteractor.respondError(topic: topic, requestId: request.id!, protocolMethod: protocolMethod, reason: PairError.methodUnsupported)
                }
            }.store(in: &publishers)
    }

}
