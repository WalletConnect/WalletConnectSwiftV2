import Foundation
import Combine
import JSONRPC
import WalletConnectNetworking
import WalletConnectUtils
import WalletConnectPairing

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
        networkingInteractor.responseErrorSubscription(on: AuthRequestProtocolMethod())
            .sink { [unowned self] (payload: ResponseSubscriptionErrorPayload<AuthRequestParams>) in
                guard let error = AuthError(code: payload.error.code) else { return }
                onResponse?(payload.id, .failure(error))
            }.store(in: &publishers)

        networkingInteractor.responseSubscription(on: AuthRequestProtocolMethod())
            .sink { [unowned self] (payload: ResponseSubscriptionPayload<AuthRequestParams, Cacao>)  in
    
                networkingInteractor.unsubscribe(topic: payload.topic)

                let requestId = payload.id
                let cacao = payload.response
                let requestPayload = payload.request

                guard
                    let address = try? DIDPKH(iss: cacao.p.iss).account.address,
                    let message = try? messageFormatter.formatMessage(from: cacao.p)
                else { self.onResponse?(requestId, .failure(.malformedResponseParams)); return }

                guard messageFormatter.formatMessage(from: requestPayload.payloadParams, address: address) == message
                else { self.onResponse?(requestId, .failure(.messageCompromised)); return }

                guard let _ = try? signatureVerifier.verify(signature: cacao.s, message: message, address: address)
                else { self.onResponse?(requestId, .failure(.signatureVerificationFailed)); return }

                onResponse?(requestId, .success(cacao))

            }.store(in: &publishers)
    }
}
