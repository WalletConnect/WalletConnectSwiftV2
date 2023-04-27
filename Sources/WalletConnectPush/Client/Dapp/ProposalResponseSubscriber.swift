import Foundation
import Combine
import WalletConnectKMS
import WalletConnectNetworking

class ProposalResponseSubscriber {
    enum Errors: Error {
        case subscriptionTopicNotDerived
    }
    private let networkingInteractor: NetworkInteracting
    private let kms: KeyManagementServiceProtocol
    private let logger: ConsoleLogging
    private var publishers = [AnyCancellable]()
    private let metadata: AppMetadata
    private let relay: RelayProtocolOptions
    var onResponse: ((_ id: RPCID, _ result: Result<PushSubscriptionResult, PushError>) -> Void)?
    private let subscriptionsStore: CodableStore<PushSubscription>

    init(networkingInteractor: NetworkInteracting,
         kms: KeyManagementServiceProtocol,
         logger: ConsoleLogging,
         metadata: AppMetadata,
         relay: RelayProtocolOptions,
         subscriptionsStore: CodableStore<PushSubscription>) {
        self.networkingInteractor = networkingInteractor
        self.kms = kms
        self.logger = logger
        self.metadata = metadata
        self.relay = relay
        self.subscriptionsStore = subscriptionsStore
        subscribeForProposalErrors()
        subscribeForProposalResponse()
    }

    private func subscribeForProposalResponse() {
        let protocolMethod = PushRequestProtocolMethod()
        networkingInteractor.responseSubscription(on: protocolMethod)
            .sink { [unowned self] (payload: ResponseSubscriptionPayload<PushRequestParams, SubscriptionJWTPayload.Wrapper>) in
                logger.debug("Received Push Proposal response")
                Task(priority: .userInitiated) {
                    do {
                        let (pushSubscription, jwt) = try await handleResponse(payload: payload)
                        let result = PushSubscriptionResult(pushSubscription: pushSubscription, subscriptionAuth: jwt)
                        onResponse?(payload.id, .success(result))
                    } catch {
                        logger.error(error)
                    }
                }
            }.store(in: &publishers)
    }

    private func handleResponse(payload: ResponseSubscriptionPayload<PushRequestParams, SubscriptionJWTPayload.Wrapper>) async throws -> (PushSubscription, String) {

        let jwt = payload.response.jwtString
        let (_, claims) = try SubscriptionJWTPayload.decodeAndVerify(from: payload.response)
        logger.debug("subscriptionAuth JWT validated")

        guard let subscriptionTopic = payload.derivedTopic else { throw Errors.subscriptionTopicNotDerived }
        let expiry = Date(timeIntervalSince1970: TimeInterval(claims.exp))

        let pushSubscription = PushSubscription(topic: subscriptionTopic, account: payload.request.account, relay: relay, metadata: metadata, scope: [:], expiry: expiry)
        logger.debug("Subscribing to Push Subscription topic: \(subscriptionTopic)")
        subscriptionsStore.set(pushSubscription, forKey: subscriptionTopic)
        try await networkingInteractor.subscribe(topic: subscriptionTopic)
        return (pushSubscription, jwt)
    }

    private func generateAgreementKeys(peerPublicKeyHex: String, selfpublicKeyHex: String) throws -> String {
        let selfPublicKey = try AgreementPublicKey(hex: selfpublicKeyHex)
        let keys = try kms.performKeyAgreement(selfPublicKey: selfPublicKey, peerPublicKey: peerPublicKeyHex)
        let topic = keys.derivedTopic()
        try kms.setAgreementSecret(keys, topic: topic)
        return topic
    }

    private func subscribeForProposalErrors() {
        let protocolMethod = PushRequestProtocolMethod()
        networkingInteractor.responseErrorSubscription(on: protocolMethod)
            .sink { [unowned self] (payload: ResponseSubscriptionErrorPayload<PushRequestParams>) in
                kms.deletePrivateKey(for: payload.request.publicKey)
                guard let error = PushError(code: payload.error.code) else { return }
                onResponse?(payload.id, .failure(error))
            }.store(in: &publishers)
    }
}
