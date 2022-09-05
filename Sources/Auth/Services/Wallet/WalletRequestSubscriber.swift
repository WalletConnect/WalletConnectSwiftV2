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
    var onRequest: ((AuthRequest) -> Void)?

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

        networkingInteractor.requestSubscription(on: AuthProtocolMethod.request)
            .sink { [unowned self] (payload: RequestSubscriptionPayload<AuthRequestParams>) in
                logger.debug("WalletRequestSubscriber: Received request")
                let message = messageFormatter.formatMessage(from: payload.request.payloadParams, address: address)
                onRequest?(.init(id: payload.id, message: message))
            }.store(in: &publishers)
    }

    private func respondError(_ error: AuthError, topic: String, requestId: RPCID) {
        guard let pubKey = kms.getAgreementSecret(for: topic)?.publicKey
        else { return logger.error("Agreement key for topic \(topic) not found") }

        let tag = AuthProtocolMethod.request.tag
        let envelopeType = Envelope.EnvelopeType.type1(pubKey: pubKey.rawRepresentation)

        Task(priority: .high) {
            try await networkingInteractor.respondError(topic: topic, requestId: requestId, tag: tag, reason: error, envelopeType: envelopeType)
        }
    }
}
