import Foundation
import Combine

class AppRespondSubscriber {
    private let networkingInteractor: NetworkInteracting
    private let logger: ConsoleLogging
    private let rpcHistory: RPCHistory
    private let signatureVerifier: MessageSignatureVerifying
    private let messageFormatter: SIWEMessageFormatting
    private let pairingRegisterer: PairingRegisterer
    private var publishers = [AnyCancellable]()

    var onResponse: ((_ id: RPCID, _ result: Result<Cacao, AuthError>) -> Void)?

    init(networkingInteractor: NetworkInteracting,
         logger: ConsoleLogging,
         rpcHistory: RPCHistory,
         signatureVerifier: MessageSignatureVerifying,
         pairingRegisterer: PairingRegisterer,
         messageFormatter: SIWEMessageFormatting) {
        self.networkingInteractor = networkingInteractor
        self.logger = logger
        self.rpcHistory = rpcHistory
        self.signatureVerifier = signatureVerifier
        self.messageFormatter = messageFormatter
        self.pairingRegisterer = pairingRegisterer
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

                pairingRegisterer.activate(pairingTopic: payload.topic)
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

                Task(priority: .high) {
                    do {
                        try await signatureVerifier.verify(
                            signature: cacao.s,
                            message: message,
                            address: address,
                            chainId: requestPayload.payloadParams.chainId
                        )
                        onResponse?(requestId, .success(cacao))
                    } catch {
                        logger.error("Signature verification failed with: \(error.localizedDescription)")
                        onResponse?(requestId, .failure(.signatureVerificationFailed))
                    }
                }
            }.store(in: &publishers)
    }
}
