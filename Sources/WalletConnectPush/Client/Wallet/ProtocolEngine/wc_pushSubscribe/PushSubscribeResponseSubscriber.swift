import Foundation
import Combine

class PushSubscribeResponseSubscriber {
    enum Errors: Error {
        case couldNotCreateSubscription
    }

    private let subscriptionErrorSubject = PassthroughSubject<Error, Never>()

    var subscriptionErrorPublisher: AnyPublisher<Error, Never> {
        return subscriptionErrorSubject.eraseToAnyPublisher()
    }

    private let networkingInteractor: NetworkInteracting
    private let kms: KeyManagementServiceProtocol
    private var publishers = [AnyCancellable]()
    private let logger: ConsoleLogging
    private let pushStorage: PushStorage
    private let groupKeychainStorage: KeychainStorageProtocol
    private let dappsMetadataStore: CodableStore<AppMetadata>
    private let subscriptionScopeProvider: SubscriptionScopeProvider

    init(networkingInteractor: NetworkInteracting,
         kms: KeyManagementServiceProtocol,
         logger: ConsoleLogging,
         groupKeychainStorage: KeychainStorageProtocol,
         pushStorage: PushStorage,
         dappsMetadataStore: CodableStore<AppMetadata>,
         subscriptionScopeProvider: SubscriptionScopeProvider
    ) {
        self.networkingInteractor = networkingInteractor
        self.kms = kms
        self.logger = logger
        self.groupKeychainStorage = groupKeychainStorage
        self.pushStorage = pushStorage
        self.dappsMetadataStore = dappsMetadataStore
        self.subscriptionScopeProvider = subscriptionScopeProvider
        subscribeForSubscriptionResponse()
    }

    private func subscribeForSubscriptionResponse() {
        let protocolMethod = PushSubscribeProtocolMethod()
        networkingInteractor.responseSubscription(on: protocolMethod)
            .sink {[unowned self] (payload: ResponseSubscriptionPayload<SubscriptionJWTPayload.Wrapper, SubscribeResponseParams>) in
                Task(priority: .high) {
                    logger.debug("PushSubscribeResponseSubscriber: Received Push Subscribe response")

                    guard let responseKeys = kms.getAgreementSecret(for: payload.topic) else {
                        logger.debug("PushSubscribeResponseSubscriber: no symmetric key for topic \(payload.topic)")
                        return subscriptionErrorSubject.send(Errors.couldNotCreateSubscription)
                    }

                    // get keypair Y
                    let pubKeyY = responseKeys.publicKey
                    let peerPubKeyZ = payload.response.publicKey

                    var account: Account!
                    var metadata: AppMetadata!
                    var pushSubscriptionTopic: String!
                    var subscribedTypes: Set<NotificationType>!
                    var agreementKeysP: AgreementKeys!
                    let (subscriptionPayload, claims) = try SubscriptionJWTPayload.decodeAndVerify(from: payload.request)
                    let subscribedScope = subscriptionPayload.scope
                        .components(separatedBy: " ")
                    do {
                        // generate symm key P
                        agreementKeysP = try kms.performKeyAgreement(selfPublicKey: pubKeyY, peerPublicKey: peerPubKeyZ)
                        pushSubscriptionTopic = agreementKeysP.derivedTopic()
                        try kms.setAgreementSecret(agreementKeysP, topic: pushSubscriptionTopic)
                        try groupKeychainStorage.add(agreementKeysP, forKey: pushSubscriptionTopic)
                        account = try Account(DIDPKHString: claims.sub)
                        metadata = try dappsMetadataStore.get(key: payload.topic)
                        let availableTypes = try await subscriptionScopeProvider.getSubscriptionScope(dappUrl: metadata!.url)
                        subscribedTypes = availableTypes.filter{subscribedScope.contains($0.name)}
                        logger.debug("PushSubscribeResponseSubscriber: subscribing push subscription topic: \(pushSubscriptionTopic!)")
                        try await networkingInteractor.subscribe(topic: pushSubscriptionTopic)
                    } catch {
                        logger.debug("PushSubscribeResponseSubscriber: error: \(error)")
                        return subscriptionErrorSubject.send(Errors.couldNotCreateSubscription)
                    }

                    guard let metadata = metadata else {
                        logger.debug("PushSubscribeResponseSubscriber: no metadata for topic: \(pushSubscriptionTopic!)")
                        return subscriptionErrorSubject.send(Errors.couldNotCreateSubscription)
                    }
                    dappsMetadataStore.delete(forKey: payload.topic)
                    let expiry = Date(timeIntervalSince1970: TimeInterval(claims.exp))
                    let scope: [String: ScopeValue] = subscribedTypes.reduce(into: [:]) { $0[$1.name] = ScopeValue(description: $1.description, enabled: true) }
                    let pushSubscription = PushSubscription(topic: pushSubscriptionTopic, account: account, relay: RelayProtocolOptions(protocol: "irn", data: nil), metadata: metadata, scope: scope, expiry: expiry, symKey: agreementKeysP.sharedKey.hexRepresentation)

                    try await pushStorage.setSubscription(pushSubscription)

                    logger.debug("PushSubscribeResponseSubscriber: unsubscribing response topic: \(payload.topic)")
                    networkingInteractor.unsubscribe(topic: payload.topic)
                }
            }.store(in: &publishers)
    }

    // TODO: handle error response

}
