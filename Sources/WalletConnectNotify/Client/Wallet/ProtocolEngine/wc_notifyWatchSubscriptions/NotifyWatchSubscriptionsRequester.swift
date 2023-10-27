import Foundation
import Combine

protocol NotifyWatchSubscriptionsRequesting {
    func watchSubscriptions() async throws
}

class NotifyWatchSubscriptionsRequester: NotifyWatchSubscriptionsRequesting {

    private let keyserverURL: URL
    private let identityClient: IdentityClient
    private let networkingInteractor: NetworkInteracting
    private let logger: ConsoleLogging
    private let webDidResolver: NotifyWebDidResolver
    private let notifyAccountProvider: NotifyAccountProvider
    private let notifyWatcherAgreementKeysProvider: NotifyWatcherAgreementKeysProvider
    private let notifyHost: String
    private var publishers = Set<AnyCancellable>()

    init(keyserverURL: URL,
         networkingInteractor: NetworkInteracting,
         identityClient: IdentityClient,
         logger: ConsoleLogging,
         webDidResolver: NotifyWebDidResolver,
         notifyAccountProvider: NotifyAccountProvider,
         notifyWatcherAgreementKeysProvider: NotifyWatcherAgreementKeysProvider,
         notifyHost: String
    ) {
        self.keyserverURL = keyserverURL
        self.identityClient = identityClient
        self.networkingInteractor = networkingInteractor
        self.logger = logger
        self.webDidResolver = webDidResolver
        self.notifyAccountProvider = notifyAccountProvider
        self.notifyWatcherAgreementKeysProvider = notifyWatcherAgreementKeysProvider
        self.notifyHost = notifyHost
    }

    func watchSubscriptions() async throws {
        let account = try notifyAccountProvider.getCurrentAccount()

        logger.debug("Watching subscriptions")

        let didDoc = try await webDidResolver.resolveDidDoc(appDomain: notifyHost)
        let notifyServerPublicKey = try webDidResolver.resolveAgreementKey(didDoc: didDoc)
        let notifyServerAuthenticationKey = try webDidResolver.resolveAuthenticationKey(didDoc: didDoc)

        let notifyServerAuthenticationDidKey = DIDKey(rawData: notifyServerAuthenticationKey)
        let watchSubscriptionsTopic = notifyServerPublicKey.rawRepresentation.sha256().toHexString()

        let (responseTopic, selfPubKeyY) = try notifyWatcherAgreementKeysProvider.generateAgreementKeysIfNeeded(notifyServerPublicKey: notifyServerPublicKey, account: account)

        logger.debug("setting symm key for response topic \(responseTopic)")

        let protocolMethod = NotifyWatchSubscriptionsProtocolMethod()

        let watchSubscriptionsAuthWrapper = try await createJWTWrapper(
            notifyServerAuthenticationDidKey: notifyServerAuthenticationDidKey,
            subscriptionAccount: account)

        let request = RPCRequest(method: protocolMethod.method, params: watchSubscriptionsAuthWrapper)

        logger.debug("Subscribing to response topic: \(responseTopic)")

        try await networkingInteractor.subscribe(topic: responseTopic)

        try await networkingInteractor.request(request, topic: watchSubscriptionsTopic, protocolMethod: protocolMethod, envelopeType: .type1(pubKey: selfPubKeyY))
    }

    private func createJWTWrapper(notifyServerAuthenticationDidKey: DIDKey, subscriptionAccount: Account) async throws -> NotifyWatchSubscriptionsPayload.Wrapper {
        let jwtPayload = NotifyWatchSubscriptionsPayload(notifyServerAuthenticationKey: notifyServerAuthenticationDidKey, keyserver: keyserverURL, subscriptionAccount: subscriptionAccount)
        return try identityClient.signAndCreateWrapper(
            payload: jwtPayload,
            account: subscriptionAccount
        )
    }
}

#if DEBUG
class MockNotifyWatchSubscriptionsRequester: NotifyWatchSubscriptionsRequesting {
    var onWatchSubscriptions: (() -> Void)?

    func watchSubscriptions() async throws {
        onWatchSubscriptions?()
    }
}
#endif
