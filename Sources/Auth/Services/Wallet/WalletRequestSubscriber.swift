import Combine
import Foundation
import WalletConnectUtils
import JSONRPC
import WalletConnectKMS

class WalletRequestSubscriber {
    private let networkingInteractor: NetworkInteracting
    private let logger: ConsoleLogging
    private let kms: KeyManagementServiceProtocol
    private let address: String?
    private var publishers = [AnyCancellable]()
    private let messageFormatter: SIWEMessageFormatting
    var onRequest: ((_ id: RPCID, _ message: String) -> Void)?

    init(networkingInteractor: NetworkInteracting,
         logger: ConsoleLogging,
         kms: KeyManagementServiceProtocol,
         messageFormatter: SIWEMessageFormatting,
         address: String?) {
        self.networkingInteractor = networkingInteractor
        self.logger = logger
        self.kms = kms
        self.address = address
        self.messageFormatter = messageFormatter
        subscribeForRequest()
    }

    private func subscribeForRequest() {
        guard let address = address else { return }

        networkingInteractor.requestPublisher.sink { [unowned self] payload in

            logger.debug("WalletRequestSubscriber: Received request")

            guard let requestId = payload.request.id, payload.request.method == "wc_authRequest"
            else { return }

            guard let authRequestParams = try? payload.request.params?.get(AuthRequestParams.self)
            else { return respondError(.malformedRequestParams, topic: payload.topic, requestId: requestId) }

            let message = messageFormatter.formatMessage(from: authRequestParams.payloadParams, address: address)

            onRequest?(requestId, message)
        }.store(in: &publishers)
    }

    private func respondError(_ error: AuthError, topic: String, requestId: RPCID) {
        guard let pubKey = kms.getAgreementSecret(for: topic)?.publicKey
        else { return logger.error("Agreement key for topic \(topic) not found") }

        let tag = AuthResponseParams.tag
        let envelopeType = Envelope.EnvelopeType.type1(pubKey: pubKey.rawRepresentation)

        Task(priority: .high) {
            try await networkingInteractor.respondError(topic: topic, requestId: requestId, tag: tag, reason: error, envelopeType: envelopeType)
        }
    }
}
