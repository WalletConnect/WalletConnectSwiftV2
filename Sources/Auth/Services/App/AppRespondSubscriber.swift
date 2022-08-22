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

    var onResponse: ((_ id: RPCID, _ result: Result<Cacao, AuthError>) -> Void)?

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
                let requestId = subscriptionPayload.response.id,
                let request = rpcHistory.get(recordId: requestId)?.request,
                let requestParams = request.params, request.method == "wc_authRequest"
            else { return }

            networkingInteractor.unsubscribe(topic: subscriptionPayload.topic)

            guard
                let cacao = try? subscriptionPayload.response.result?.get(Cacao.self),
                let address = try? DIDPKH(iss: cacao.payload.iss).account.address,
                let message = try? messageFormatter.formatMessage(from: cacao.payload)
            else { self.onResponse?(requestId, .failure(.malformedResponseParams)); return }

            guard let requestPayload = try? requestParams.get(AuthRequestParams.self)
            else { self.onResponse?(requestId, .failure(.malformedRequestParams)); return }

            guard messageFormatter.formatMessage(from: requestPayload.payloadParams, address: address) == message
            else { self.onResponse?(requestId, .failure(.messageCompromised)); return }

            guard let _ = try? signatureVerifier.verify(signature: cacao.signature.s, message: message, address: address)
            else { self.onResponse?(requestId, .failure(.messageVerificationFailed)); return }

            onResponse?(requestId, .success(cacao))

        }.store(in: &publishers)
    }
}
