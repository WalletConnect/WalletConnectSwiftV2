import Foundation
import Combine

protocol NotifyWatchSubscriptionsRequesting {
    func setAccount(_ account: Account)
    func watchSubscriptions() async throws
}

class NotifyWatchSubscriptionsRequester: NotifyWatchSubscriptionsRequesting {

    private let keyserverURL: URL
    private let identityClient: IdentityClient
    private let networkingInteractor: NetworkInteracting
    private let kms: KeyManagementService
    private let logger: ConsoleLogging
    private let webDidResolver: NotifyWebDidResolver
    private let notifyHost: String
    private var account: Account?
    private var publishers = Set<AnyCancellable>()

    init(keyserverURL: URL,
         networkingInteractor: NetworkInteracting,
         identityClient: IdentityClient,
         logger: ConsoleLogging,
         kms: KeyManagementService,
         webDidResolver: NotifyWebDidResolver,
         notifyHost: String
    ) {
        self.keyserverURL = keyserverURL
        self.identityClient = identityClient
        self.networkingInteractor = networkingInteractor
        self.logger = logger
        self.kms = kms
        self.webDidResolver = webDidResolver
        self.notifyHost = notifyHost
    }

    func setAccount(_ account: Account) {
        self.account = account
    }

    func watchSubscriptions() async throws {

        guard let account = account else { return }

        logger.debug("Watching subscriptions")

        let notifyServerPublicKey = try await webDidResolver.resolveAgreementKey(domain: notifyHost)
        let notifyServerAuthenticationKey = try await webDidResolver.resolveAuthenticationKey(domain: notifyHost)
        let notifyServerAuthenticationDidKey = DIDKey(rawData: notifyServerAuthenticationKey)
        let watchSubscriptionsTopic = notifyServerPublicKey.rawRepresentation.sha256().toHexString()

        let (responseTopic, selfPubKeyY) = try generateAgreementKeysIfNeeded(notifyServerPublicKey: notifyServerPublicKey, account: account)



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


    private func generateAgreementKeysIfNeeded(notifyServerPublicKey: AgreementPublicKey, account: Account) throws -> (responseTopic: String, selfPubKeyY: Data) {

        let keyYStorageKey = "\(account)_\(notifyServerPublicKey.hexRepresentation)"

        if let responseTopic = kms.getTopic(for: keyYStorageKey),
           let selfPubKeyY = kms.getAgreementSecret(for: responseTopic)?.publicKey {
            return (responseTopic: responseTopic, selfPubKeyY: selfPubKeyY.rawRepresentation)
        } else {
            let selfPubKeyY = try kms.createX25519KeyPair()
            let watchSubscriptionsTopic = notifyServerPublicKey.rawRepresentation.sha256().toHexString()

            let agreementKeys = try kms.performKeyAgreement(selfPublicKey: selfPubKeyY, peerPublicKey: notifyServerPublicKey.hexRepresentation)

            try kms.setSymmetricKey(agreementKeys.sharedKey, for: watchSubscriptionsTopic)
            let responseTopic = agreementKeys.derivedTopic()

            try kms.setAgreementSecret(agreementKeys, topic: responseTopic)

            // save for later under dapp's account + pub key
            try kms.setTopic(responseTopic, for: keyYStorageKey)

            return (responseTopic: responseTopic, selfPubKeyY: selfPubKeyY.rawRepresentation)
        }
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
    func setAccount(_ account: WalletConnectUtils.Account) {}

    var onWatchSubscriptions: (() -> Void)?

    func watchSubscriptions() async throws {
        onWatchSubscriptions?()
    }
}
#endif
