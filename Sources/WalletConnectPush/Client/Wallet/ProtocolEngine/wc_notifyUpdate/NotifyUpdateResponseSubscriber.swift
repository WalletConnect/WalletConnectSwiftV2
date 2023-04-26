
import Foundation
import Combine

class NotifyUpdateResponseSubscriber {
    enum Errors: Error {
        case subscriptionDoesNotExist
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
        subscribeForUpdateResponse()
    }

    private func subscribeForUpdateResponse() {
        let protocolMethod = NotifyUpdateProtocolMethod()
        networkingInteractor.responseSubscription(on: protocolMethod)
            .sink {[unowned self] (payload: ResponseSubscriptionPayload<SubscriptionJWTPayload.Wrapper, Bool>) in
                Task(priority: .high) {
                    logger.debug("Received Push Update response")

                    let subscriptionTopic = payload.topic

                    // force unwrap is safe because jwt has been signed by self peer
                    let (_, claims) = try SubscriptionJWTPayload.decodeAndVerify(from: payload.request)
                    let updatedScopeString = claims.scp

                    let scope = updatedScopeString
                        .components(separatedBy: " ")
                        .compactMap { NotificationScope(rawValue: $0) }

                    guard let oldSubscription = try? subscriptionsStore.get(key: subscriptionTopic) else {
                        logger.debug("NotifyUpdateResponseSubscriber Subscription does not exist")
                        subscriptionPublisherSubject.send(.failure(Errors.subscriptionDoesNotExist))
                        return
                    }

                    let updatedSubscription = PushSubscription(topic: subscriptionTopic, account: oldSubscription.account, relay: oldSubscription.relay, metadata: oldSubscription.metadata, scope: Set(scope))

                    subscriptionsStore.set(updatedSubscription, forKey: subscriptionTopic)

                    subscriptionPublisherSubject.send(.success(updatedSubscription))

                    logger.debug("Updated Subscription")
                }
            }.store(in: &publishers)
    }
}
