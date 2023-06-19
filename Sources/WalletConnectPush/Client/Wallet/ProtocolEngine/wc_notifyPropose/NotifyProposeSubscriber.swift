
import Foundation
import Combine

class NotifyProposeSubscriber {

    private let requestPublisherSubject = PassthroughSubject<PushRequest, Never>()
    private let networkingInteractor: NetworkInteracting

    public var requestPublisher: AnyPublisher<PushRequest, Never> {
        requestPublisherSubject.eraseToAnyPublisher()
    }
    private let subscriptionsStore: CodableStore<PushSubscription>

    private var publishers = Set<AnyCancellable>()

    public let logger: ConsoleLogging

    private let pairingRegisterer: PairingRegisterer

    init(pairingRegisterer: PairingRegisterer) {
        self.pairingRegisterer = pairingRegisterer
        setupSubscription()
    }



    func setupSubscription() {
        pairingRegisterer.register(method: NotifyProposeProtocolMethod())
            .sink { [unowned self] (payload: RequestSubscriptionPayload<NotifyProposeParams>) in

                logger.debug("NotifyProposeSubscriber - new notify propose request")



                guard subscriptionsStore.getAll().contains(<#T##other: Collection##Collection#>) else {
                    respondError(requestId: payload.id, pairingTopic: payload.topic)
                    return
                }

                requestPublisherSubject.send((id: payload.id, account: payload.request.account, metadata: payload.request.metadata))
            }.store(in: &publishers)

    }


    func respondError(requestId: RPCID, pairingTopic: String) async throws {
        logger.debug("NotifyProposeSubscriber - responding error for notify propose")

        let pairingTopic = pairingTopic

        try await networkingInteractor.respondError(topic: pairingTopic, requestId: requestId, protocolMethod: NotifyProposeProtocolMethod(), reason: PushError.userHasExistingSubscription)
    }
}
