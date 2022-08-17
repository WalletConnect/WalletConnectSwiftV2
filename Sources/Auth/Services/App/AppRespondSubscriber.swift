import Combine
import Foundation
import WalletConnectUtils
import JSONRPC

class AppRespondSubscriber {
    private let networkingInteractor: NetworkInteracting
    private let logger: ConsoleLogging
    private let rpcHistory: RPCHistory
    private let signatureVerifier: MessageSignatureVerifying
    private let messageFormatter: SIWEMessageFormatting
    private var publishers = [AnyCancellable]()
    var onResponse: ((_ id: RPCID, _ result: Result<Cacao, ErrorCode>) -> Void)?

    init(networkingInteractor: NetworkInteracting,
         logger: ConsoleLogging,
         rpcHistory: RPCHistory,
         signatureVerifier: MessageSignatureVerifying,
         messageFormatter: SIWEMessageFormatting) {
        self.networkingInteractor = networkingInteractor
        self.logger = logger
        self.rpcHistory = rpcHistory
        self.signatureVerifier = signatureVerifier
        self.messageFormatter = messageFormatter
        subscribeForResponse()
    }

    private func subscribeForResponse() {
        // TODO - handle error response
        networkingInteractor.responsePublisher.sink { [unowned self] subscriptionPayload in
            guard
                let requestId = subscriptionPayload.request.id,
                let request = rpcHistory.get(recordId: requestId)?.request,
                let requestParams = request.params, request.method == "wc_authRequest"
            else { return }

            networkingInteractor.unsubscribe(topic: subscriptionPayload.topic)

            do {
                guard let cacao = try subscriptionPayload.request.result?.get(Cacao.self) else {
                    return logger.debug("Malformed auth response params")
                }

                let requestPayload = try requestParams.get(AuthRequestParams.self)
                let address = try DIDPKH(iss: cacao.payload.iss).account.address
                let message = try messageFormatter.formatMessage(from: cacao.payload)
                let originalMessage = messageFormatter.formatMessage(from: requestPayload.payloadParams, address: address)

                guard originalMessage == message else {
                    return logger.debug("Original message compromised")
                }

                try signatureVerifier.verify(
                    signature: cacao.signature.s,
                    message: message,
                    address: address
                )
                onResponse?(requestId, .success(cacao))
            } catch {
                logger.debug("Received response with invalid signature")
            }
        }.store(in: &publishers)
    }
}
