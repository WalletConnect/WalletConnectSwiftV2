
import Foundation
import Combine

class PushSubscribeResponseSubscriber {
    enum Errors: Error {
        case couldNotCreateSubscription
    }

    private let networkingInteractor: NetworkInteracting
    private let kms: KeyManagementServiceProtocol
    private var publishers = [AnyCancellable]()
    private let logger: ConsoleLogging
    private let subscriptionsStore: CodableStore<PushSubscription>
    private let groupKeychainStorage: KeychainStorageProtocol
    private let dappsMetadataStore: CodableStore<AppMetadata>
    private var subscriptionPublisherSubject = PassthroughSubject<Result<PushSubscription, Error>, Never>()
    var subscriptionPublisher: AnyPublisher<Result<PushSubscription, Error>, Never> {
        return subscriptionPublisherSubject.eraseToAnyPublisher()
    }

    init(networkingInteractor: NetworkInteracting,
         kms: KeyManagementServiceProtocol,
         logger: ConsoleLogging,
         groupKeychainStorage: KeychainStorageProtocol,
         subscriptionsStore: CodableStore<PushSubscription>,
         dappsMetadataStore: CodableStore<AppMetadata>
    ) {
        self.networkingInteractor = networkingInteractor
        self.kms = kms
        self.logger = logger
        self.groupKeychainStorage = groupKeychainStorage
        self.subscriptionsStore = subscriptionsStore
        self.dappsMetadataStore = dappsMetadataStore
        subscribeForSubscriptionResponse()
    }

    private func subscribeForSubscriptionResponse() {
        let protocolMethod = PushSubscribeProtocolMethod()
        networkingInteractor.responseSubscription(on: protocolMethod)
            .sink {[unowned self] (payload: ResponseSubscriptionPayload<CreateSubscriptionJWTPayload.Wrapper, Bool>) in
                logger.debug("Received Push Subscribe response")

                guard let pushSubscryptionKey = kms.getAgreementSecret(for: payload.topic) else {
                    logger.debug("PushSubscribeResponseSubscriber: no sym key for topic")
                    subscriptionPublisherSubject.send(.failure(Errors.couldNotCreateSubscription))
                    return
                }
                let pushSubscriptionTopic = pushSubscryptionKey.derivedTopic()

                var account: Account!
                var metadata: AppMetadata!
                do {
                    try kms.setAgreementSecret(pushSubscryptionKey, topic: pushSubscriptionTopic)
                    try groupKeychainStorage.add(pushSubscryptionKey, forKey: pushSubscriptionTopic)
                    let (_, claims) = try CreateSubscriptionJWTPayload.decodeAndVerify(from: payload.request)
                    account = try Account(DIDPKHString: claims.sub)
                    metadata = try dappsMetadataStore.get(key: payload.topic)
                } catch {
                    logger.debug("PushSubscribeResponseSubscriber: error: \(error)")
                    subscriptionPublisherSubject.send(.failure(Errors.couldNotCreateSubscription))
                    return
                }

                dappsMetadataStore.delete(forKey: payload.topic)

                let pushSubscription = PushSubscription(topic: pushSubscriptionTopic, account: account, relay: RelayProtocolOptions(protocol: "irn", data: nil), metadata: metadata)

                subscriptionsStore.set(pushSubscription, forKey: pushSubscriptionTopic)

                subscriptionPublisherSubject.send(.success(pushSubscription))

                logger.debug("Subscribing to push topic: \(pushSubscriptionTopic)")

                Task { try await networkingInteractor.subscribe(topic: pushSubscriptionTopic) }

            }.store(in: &publishers)
    }
}
