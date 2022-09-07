import Foundation
import Combine
import JSONRPC
import WalletConnectNetworking
import WalletConnectUtils
import WalletConnectKMS

class WalletRequestSubscriber {
    private let networkingInteractor: NetworkInteracting
    private let logger: ConsoleLogging
    private let kms: KeyManagementServiceProtocol
    private let address: String?
    private var publishers = [AnyCancellable]()
    private let messageFormatter: SIWEMessageFormatting
    private let walletErrorResponder: WalletErrorResponder
    var onRequest: ((AuthRequest) -> Void)?

    init(networkingInteractor: NetworkInteracting,
         logger: ConsoleLogging,
         kms: KeyManagementServiceProtocol,
         messageFormatter: SIWEMessageFormatting,
         address: String?,
         walletErrorResponder: WalletErrorResponder) {
        self.networkingInteractor = networkingInteractor
        self.logger = logger
        self.kms = kms
        self.address = address
        self.messageFormatter = messageFormatter
        self.walletErrorResponder = walletErrorResponder
        subscribeForRequest()
    }

    private func subscribeForRequest() {
        guard let address = address else { return }

        networkingInteractor.requestSubscription(on: AuthProtocolMethod.authRequest)
            .sink { [unowned self] (payload: RequestSubscriptionPayload<AuthRequestParams>) in
                logger.debug("WalletRequestSubscriber: Received request")
                guard let message = messageFormatter.formatMessage(from: payload.request.payloadParams, address: address) else {
                    Task {
                        try? await walletErrorResponder.respondError(AuthError.malformedRequestParams, requestId: payload.id)
                    }
                    return
                }
                onRequest?(.init(id: payload.id, message: message))
            }.store(in: &publishers)
    }
}


actor WalletErrorResponder {
    enum Errors: Error {
        case recordForIdNotFound
        case malformedAuthRequestParams
    }

    private let networkingInteractor: NetworkInteracting
    private let kms: KeyManagementServiceProtocol
    private let rpcHistory: RPCHistory
    private let logger: ConsoleLogging

    init(networkingInteractor: NetworkInteracting,
         logger: ConsoleLogging,
         kms: KeyManagementServiceProtocol,
         rpcHistory: RPCHistory) {
        self.networkingInteractor = networkingInteractor
        self.logger = logger
        self.kms = kms
        self.rpcHistory = rpcHistory
    }


    func respondError(_ error: AuthError, requestId: RPCID) async throws {
        let authRequestParams = try getAuthRequestParams(requestId: requestId)
        let (topic, keys) = try generateAgreementKeys(requestParams: authRequestParams)

        try kms.setAgreementSecret(keys, topic: topic)

        let tag = AuthProtocolMethod.authRequest.responseTag
        let envelopeType = Envelope.EnvelopeType.type1(pubKey: keys.publicKey.rawRepresentation)
        try await networkingInteractor.respondError(topic: topic, requestId: requestId, tag: tag, reason: error, envelopeType: envelopeType)
    }


    private func getAuthRequestParams(requestId: RPCID) throws -> AuthRequestParams {
        guard let request = rpcHistory.get(recordId: requestId)?.request
        else { throw Errors.recordForIdNotFound }

        guard let authRequestParams = try request.params?.get(AuthRequestParams.self)
        else { throw Errors.malformedAuthRequestParams }

        return authRequestParams
    }

    private func generateAgreementKeys(requestParams: AuthRequestParams) throws -> (topic: String, keys: AgreementKeys) {
        let peerPubKey = try AgreementPublicKey(hex: requestParams.requester.publicKey)
        let topic = peerPubKey.rawRepresentation.sha256().toHexString()
        let selfPubKey = try kms.createX25519KeyPair()
        let keys = try kms.performKeyAgreement(selfPublicKey: selfPubKey, peerPublicKey: peerPubKey.hexRepresentation)
        return (topic, keys)
    }
}
