import Foundation
import Combine
import WalletConnectKMS
import WalletConnectNetworking

class ProposalResponseSubscriber {
    private let networkingInteractor: NetworkInteracting
    private let kms: KeyManagementServiceProtocol
    private let logger: ConsoleLogging
    private var publishers = [AnyCancellable]()
    private let metadata: AppMetadata
    private let relay: RelayProtocolOptions
    var onResponse: ((_ id: RPCID, _ result: Result<PushSubscription, PushError>) -> Void)?
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
            .sink { [unowned self] (payload: ResponseSubscriptionPayload<PushRequestParams, PushResponseParams>) in
                logger.debug("Received Push Proposal response")
                Task(priority: .userInitiated) {
                    let pushSubscription = try await handleResponse(payload: payload)
                    onResponse?(payload.id, .success(pushSubscription))
                }
            }.store(in: &publishers)
    }

    private func handleResponse(payload: ResponseSubscriptionPayload<PushRequestParams, PushResponseParams>) async throws -> PushSubscription {
        let peerPublicKeyHex = payload.response.publicKey
        let selfpublicKeyHex = payload.request.publicKey
        let (topic, _) = try generateAgreementKeys(peerPublicKeyHex: peerPublicKeyHex, selfpublicKeyHex: selfpublicKeyHex)

        let pushSubscription = PushSubscription(topic: topic, account: payload.request.account, relay: relay, metadata: metadata)
        subscriptionsStore.set(pushSubscription, forKey: topic)
        kms.deletePrivateKey(for: selfpublicKeyHex)
        try await networkingInteractor.subscribe(topic: topic)
        return pushSubscription
    }

    private func generateAgreementKeys(peerPublicKeyHex: String, selfpublicKeyHex: String) throws -> (topic: String, keys: AgreementKeys) {
        let selfPublicKey = try AgreementPublicKey(hex: selfpublicKeyHex)
        let keys = try kms.performKeyAgreement(selfPublicKey: selfPublicKey, peerPublicKey: peerPublicKeyHex)
        let topic = keys.derivedTopic()
        try kms.setAgreementSecret(keys, topic: topic)
        return (topic: topic, keys: keys)
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
