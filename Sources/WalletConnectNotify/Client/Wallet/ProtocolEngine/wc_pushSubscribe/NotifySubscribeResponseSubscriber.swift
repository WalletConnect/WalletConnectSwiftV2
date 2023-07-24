import Foundation
import Combine

class NotifySubscribeResponseSubscriber {
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
    private let notifyStorage: NotifyStorage
    private let groupKeychainStorage: KeychainStorageProtocol
    private let dappsMetadataStore: CodableStore<AppMetadata>
    private let subscriptionScopeProvider: SubscriptionScopeProvider

    init(networkingInteractor: NetworkInteracting,
         kms: KeyManagementServiceProtocol,
         logger: ConsoleLogging,
         groupKeychainStorage: KeychainStorageProtocol,
         notifyStorage: NotifyStorage,
         dappsMetadataStore: CodableStore<AppMetadata>,
         subscriptionScopeProvider: SubscriptionScopeProvider
    ) {
        self.networkingInteractor = networkingInteractor
        self.kms = kms
        self.logger = logger
        self.groupKeychainStorage = groupKeychainStorage
        self.notifyStorage = notifyStorage
        self.dappsMetadataStore = dappsMetadataStore
        self.subscriptionScopeProvider = subscriptionScopeProvider
        subscribeForSubscriptionResponse()
    }

    private func subscribeForSubscriptionResponse() {
        let protocolMethod = NotifySubscribeProtocolMethod()
        networkingInteractor.responseSubscription(on: protocolMethod)
            .sink {[unowned self] (payload: ResponseSubscriptionPayload<SubscriptionJWTPayload.Wrapper, SubscribeResponseParams>) in
                Task(priority: .high) {
                    logger.debug("NotifySubscribeResponseSubscriber: Received Notify Subscribe response")

                    guard let responseKeys = kms.getAgreementSecret(for: payload.topic) else {
                        logger.debug("NotifySubscribeResponseSubscriber: no symmetric key for topic \(payload.topic)")
                        return subscriptionErrorSubject.send(Errors.couldNotCreateSubscription)
                    }

                    // get keypair Y
                    let pubKeyY = responseKeys.publicKey
                    let peerPubKeyZ = payload.response.publicKey

                    var account: Account!
                    var metadata: AppMetadata!
                    var notifySubscriptionTopic: String!
                    var subscribedTypes: Set<NotificationType>!
                    var agreementKeysP: AgreementKeys!
                    let (subscriptionPayload, claims) = try SubscriptionJWTPayload.decodeAndVerify(from: payload.request)
                    let subscribedScope = subscriptionPayload.scope
                        .components(separatedBy: " ")
                    do {
                        // generate symm key P
                        agreementKeysP = try kms.performKeyAgreement(selfPublicKey: pubKeyY, peerPublicKey: peerPubKeyZ)
                        notifySubscriptionTopic = agreementKeysP.derivedTopic()
                        try kms.setAgreementSecret(agreementKeysP, topic: notifySubscriptionTopic)
                        try groupKeychainStorage.add(agreementKeysP, forKey: notifySubscriptionTopic)
                        account = try Account(DIDPKHString: claims.sub)
                        metadata = try dappsMetadataStore.get(key: payload.topic)
                        let availableTypes = try await subscriptionScopeProvider.getSubscriptionScope(dappUrl: metadata!.url)
                        subscribedTypes = availableTypes.filter{subscribedScope.contains($0.name)}
                        logger.debug("NotifySubscribeResponseSubscriber: subscribing notify subscription topic: \(notifySubscriptionTopic!)")
                        try await networkingInteractor.subscribe(topic: notifySubscriptionTopic)
                    } catch {
                        logger.debug("NotifySubscribeResponseSubscriber: error: \(error)")
                        return subscriptionErrorSubject.send(Errors.couldNotCreateSubscription)
                    }

                    guard let metadata = metadata else {
                        logger.debug("NotifySubscribeResponseSubscriber: no metadata for topic: \(notifySubscriptionTopic!)")
                        return subscriptionErrorSubject.send(Errors.couldNotCreateSubscription)
                    }
                    dappsMetadataStore.delete(forKey: payload.topic)
                    let expiry = Date(timeIntervalSince1970: TimeInterval(claims.exp))
                    let scope: [String: ScopeValue] = subscribedTypes.reduce(into: [:]) { $0[$1.name] = ScopeValue(description: $1.description, enabled: true) }
                    let notifySubscription = NotifySubscription(topic: notifySubscriptionTopic, account: account, relay: RelayProtocolOptions(protocol: "irn", data: nil), metadata: metadata, scope: scope, expiry: expiry, symKey: agreementKeysP.sharedKey.hexRepresentation)

                    try await notifyStorage.setSubscription(notifySubscription)

                    logger.debug("NotifySubscribeResponseSubscriber: unsubscribing response topic: \(payload.topic)")
                    networkingInteractor.unsubscribe(topic: payload.topic)
                }
            }.store(in: &publishers)
    }

    // TODO: handle error response

}
