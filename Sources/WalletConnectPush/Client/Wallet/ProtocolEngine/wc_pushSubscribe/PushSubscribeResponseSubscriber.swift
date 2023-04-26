
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
    private let subscriptionScopeProvider: SubscriptionScopeProvider
    private var subscriptionPublisherSubject = PassthroughSubject<Result<PushSubscription, Error>, Never>()
    var subscriptionPublisher: AnyPublisher<Result<PushSubscription, Error>, Never> {
        return subscriptionPublisherSubject.eraseToAnyPublisher()
    }

    init(networkingInteractor: NetworkInteracting,
         kms: KeyManagementServiceProtocol,
         logger: ConsoleLogging,
         groupKeychainStorage: KeychainStorageProtocol,
         subscriptionsStore: CodableStore<PushSubscription>,
         dappsMetadataStore: CodableStore<AppMetadata>,
         subscriptionScopeProvider: SubscriptionScopeProvider = SubscriptionScopeProvider()
    ) {
        self.networkingInteractor = networkingInteractor
        self.kms = kms
        self.logger = logger
        self.groupKeychainStorage = groupKeychainStorage
        self.subscriptionsStore = subscriptionsStore
        self.dappsMetadataStore = dappsMetadataStore
        self.subscriptionScopeProvider = subscriptionScopeProvider
        subscribeForSubscriptionResponse()
    }

    private func subscribeForSubscriptionResponse() {
        let protocolMethod = PushSubscribeProtocolMethod()
        networkingInteractor.responseSubscription(on: protocolMethod)
            .sink {[unowned self] (payload: ResponseSubscriptionPayload<SubscriptionJWTPayload.Wrapper, Bool>) in
                Task(priority: .high) {
                    logger.debug("Received Push Subscribe response")

                    guard let pushSubscryptionKey = kms.getAgreementSecret(for: payload.topic) else {
                        logger.debug("PushSubscribeResponseSubscriber: no symmetric key for topic \(payload.topic)")
                        subscriptionPublisherSubject.send(.failure(Errors.couldNotCreateSubscription))
                        return
                    }
                    let pushSubscriptionTopic = pushSubscryptionKey.derivedTopic()

                    var account: Account!
                    var metadata: AppMetadata!
                    var scope: Set<NotificationScope>!
                    do {
                        try kms.setAgreementSecret(pushSubscryptionKey, topic: pushSubscriptionTopic)
                        try groupKeychainStorage.add(pushSubscryptionKey, forKey: pushSubscriptionTopic)
                        let (_, claims) = try SubscriptionJWTPayload.decodeAndVerify(from: payload.request)
                        account = try Account(DIDPKHString: claims.sub)
                        metadata = try dappsMetadataStore.get(key: payload.topic)
                        scope = try await subscriptionScopeProvider.getSubscriptionScope(dappUrl: metadata!.url)
                    } catch {
                        logger.debug("PushSubscribeResponseSubscriber: error: \(error)")
                        networkingInteractor.unsubscribe(topic: pushSubscriptionTopic)
                        subscriptionPublisherSubject.send(.failure(Errors.couldNotCreateSubscription))
                        return
                    }

                    guard let metadata = metadata else {
                        logger.debug("PushSubscribeResponseSubscriber: no metadata for topic: \(payload.topic)")
                        return
                    }
                    dappsMetadataStore.delete(forKey: payload.topic)

                    let pushSubscription = PushSubscription(topic: pushSubscriptionTopic, account: account, relay: RelayProtocolOptions(protocol: "irn", data: nil), metadata: metadata, scope: scope)

                    subscriptionsStore.set(pushSubscription, forKey: pushSubscriptionTopic)

                    subscriptionPublisherSubject.send(.success(pushSubscription))
                }
            }.store(in: &publishers)
    }
}
