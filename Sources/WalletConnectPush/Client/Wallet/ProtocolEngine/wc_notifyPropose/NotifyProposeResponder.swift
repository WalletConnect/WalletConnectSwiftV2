
import Foundation
import Combine

class NotifyProposeResponder {
    enum Errors: Error {
        case recordForIdNotFound
        case malformedRequestParams
        case subscriptionNotFound
    }
    private let networkingInteractor: NetworkInteracting
    private let kms: KeyManagementServiceProtocol
    private let logger: ConsoleLogging
    private let pushStorage: PushStorage
    private let pushSubscribeRequester: PushSubscribeRequester
    private let rpcHistory: RPCHistory

    private var publishers = [AnyCancellable]()

    init(networkingInteractor: NetworkInteracting,
         kms: KeyManagementServiceProtocol,
         logger: ConsoleLogging,
         pushStorage: PushStorage,
         pushSubscribeRequester: PushSubscribeRequester,
         rpcHistory: RPCHistory,
         pushSubscribeResponseSubscriber: PushSubscribeResponseSubscriber
    ) {
        self.networkingInteractor = networkingInteractor
        self.kms = kms
        self.logger = logger
        self.pushStorage = pushStorage
        self.pushSubscribeRequester = pushSubscribeRequester
        self.rpcHistory = rpcHistory
    }

    func approve(requestId: RPCID, onSign: @escaping SigningCallback) async throws {

        logger.debug("NotifyProposeResponder: approving proposal")

        guard let requestRecord = rpcHistory.get(recordId: requestId) else { throw Errors.recordForIdNotFound }
        let proposal = try requestRecord.request.params!.get(NotifyProposeParams.self)

        let subscriptionAuthWrapper = try await pushSubscribeRequester.subscribe(metadata: proposal.metadata, account: proposal.account, onSign: onSign)

        var pushSubscription: PushSubscription!
        try await withCheckedThrowingContinuation { [unowned self] continuation in
            pushStorage.newSubscriptionPublisher
                .first()
                .sink { value in
                    pushSubscription = value
                    continuation.resume()
                }.store(in: &publishers)
        }

        guard let peerPublicKey = try? AgreementPublicKey(hex: proposal.publicKey) else {
            throw Errors.malformedRequestParams
        }

        let responseTopic = peerPublicKey.rawRepresentation.sha256().toHexString()

        let keys = try generateAgreementKeys(peerPublicKey: peerPublicKey)

        try kms.setSymmetricKey(keys.sharedKey, for: responseTopic)

        guard let subscriptionKey = kms.getSymmetricKeyRepresentable(for: pushSubscription.topic)?.toHexString() else { throw Errors.subscriptionNotFound }

        let responseParams = NotifyProposeResponseParams(subscriptionAuth: subscriptionAuthWrapper.subscriptionAuth, subscriptionSymKey: subscriptionKey)

        let response = RPCResponse(id: requestId, result: responseParams)

        let protocolMethod = NotifyProposeProtocolMethod()

        logger.debug("NotifyProposeResponder: sending response")

        try await networkingInteractor.respond(topic: responseTopic, response: response, protocolMethod: protocolMethod, envelopeType: .type1(pubKey: keys.publicKey.rawRepresentation))
        kms.deleteSymmetricKey(for: responseTopic)
    }

    func reject(requestId: RPCID) async throws {
        logger.debug("NotifyProposeResponder - rejecting notify request")
        guard let requestRecord = rpcHistory.get(recordId: requestId) else { throw Errors.recordForIdNotFound }
        let pairingTopic = requestRecord.topic

        try await networkingInteractor.respondError(topic: pairingTopic, requestId: requestId, protocolMethod: NotifyProposeProtocolMethod(), reason: PushError.userRejeted)
    }

    private func generateAgreementKeys(peerPublicKey: AgreementPublicKey) throws -> AgreementKeys {
        let selfPubKey = try kms.createX25519KeyPair()
        let keys = try kms.performKeyAgreement(selfPublicKey: selfPubKey, peerPublicKey: peerPublicKey.hexRepresentation)
        return keys
    }
}

