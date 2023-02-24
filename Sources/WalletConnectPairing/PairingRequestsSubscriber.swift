import Foundation
import Combine

public class PairingRequestsSubscriber {
    private let networkingInteractor: NetworkInteracting
    private let pairingStorage: PairingStorage
    private var publishers = Set<AnyCancellable>()
    private var registeredProtocolMethods = SetStore<String>(label: "com.walletconnect.sdk.pairing.registered_protocol_methods")
    private let pairingProtocolMethods = PairingProtocolMethod.allCases.map { $0.method }
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
        registeredProtocolMethods.insert(protocolMethod.method)
        return networkingInteractor.requestSubscription(on: protocolMethod).eraseToAnyPublisher()
    }

    func handleUnregisteredRequests() {
        networkingInteractor.requestPublisher
            .filter { [unowned self] in !pairingProtocolMethods.contains($0.request.method)}
            .filter { [unowned self] in pairingStorage.hasPairing(forTopic: $0.topic)}
            .filter { [unowned self] in !registeredProtocolMethods.contains($0.request.method)}
            .sink { [unowned self] topic, request, _ in
                Task(priority: .high) {
                    let protocolMethod = UnsupportedProtocolMethod(method: request.method)
                    logger.debug("PairingRequestsSubscriber: responding unregistered request method")
                    try await networkingInteractor.respondError(topic: topic, requestId: request.id!, protocolMethod: protocolMethod, reason: PairError.methodUnsupported)
                }
            }.store(in: &publishers)
    }

}
