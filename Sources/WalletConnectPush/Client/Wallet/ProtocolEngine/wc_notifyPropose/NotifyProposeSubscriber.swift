
import Foundation
import Combine

class NotifyProposeSubscriber {

    private let requestPublisherSubject = PassthroughSubject<PushRequest, Never>()
    private let networkingInteractor: NetworkInteracting
    private let subscriptionsStore: CodableStore<PushSubscription>
    private var publishers = Set<AnyCancellable>()
    public var requestPublisher: AnyPublisher<PushRequest, Never> {
        requestPublisherSubject.eraseToAnyPublisher()
    }
    public let logger: ConsoleLogging
    private let pairingRegisterer: PairingRegisterer

    init(networkingInteractor: NetworkInteracting,
         subscriptionsStore: CodableStore<PushSubscription>,
         publishers: Set<AnyCancellable> = Set<AnyCancellable>(),
         logger: ConsoleLogging,
         pairingRegisterer: PairingRegisterer) {
        self.networkingInteractor = networkingInteractor
        self.subscriptionsStore = subscriptionsStore
        self.publishers = publishers
        self.logger = logger
        self.pairingRegisterer = pairingRegisterer
        setupSubscription()
    }

    func setupSubscription() {
        pairingRegisterer.register(method: NotifyProposeProtocolMethod())
            .sink { [unowned self] (payload: RequestSubscriptionPayload<NotifyProposeParams>) in
                logger.debug("NotifyProposeSubscriber - new notify propose request")
                guard hasNoSubscription(for: payload.request.metadata.url) else {
                    Task(priority: .high) { try await respondError(requestId: payload.id, pairingTopic: payload.topic) }
                    return
                }
                requestPublisherSubject.send((id: payload.id, account: payload.request.account, metadata: payload.request.metadata))
            }.store(in: &publishers)
    }

    func hasNoSubscription(for domain: String) -> Bool {
        subscriptionsStore.getAll().first {$0.metadata.url == domain} == nil
    }

    func respondError(requestId: RPCID, pairingTopic: String) async throws {
        logger.debug("NotifyProposeSubscriber - responding error for notify propose")

        let pairingTopic = pairingTopic

        try await networkingInteractor.respondError(topic: pairingTopic, requestId: requestId, protocolMethod: NotifyProposeProtocolMethod(), reason: PushError.userHasExistingSubscription)
    }
}
