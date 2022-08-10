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
    var onResponse: ((_ id: RPCID, _ cacao: Cacao) -> Void)?

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
        networkingInteractor.responsePublisher.sink { [unowned self] subscriptionPayload in
            guard
                let requestId = subscriptionPayload.request.id,
                let request = rpcHistory.get(recordId: requestId)?.request,
                request.method == "wc_authRequest" else { return }

            networkingInteractor.unsubscribe(topic: subscriptionPayload.topic)

            do {
                guard let cacao = try subscriptionPayload.request.result?.get(Cacao.self) else {
                    return logger.debug("Malformed auth response params")
                }

                let address = try DIDPKH(iss: cacao.payload.iss).account.address
                let payload = AuthPayload(payload: cacao.payload)
                let message = messageFormatter.formatMessage(from: payload, address: address)

                try signatureVerifier.verify(
                    signature: cacao.signature.s,
                    message: message,
                    address: cacao.payload.iss
                )
                onResponse?(requestId, cacao)
            } catch {
                logger.debug("Received response with invalid signature")
            }
        }.store(in: &publishers)
    }
}
