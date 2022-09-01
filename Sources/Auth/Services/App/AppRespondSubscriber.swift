import Foundation
import Combine
import JSONRPC
import WalletConnectNetworking
import WalletConnectUtils
import WalletConnectPairing

class AppRespondSubscriber {
    private let networkingInteractor: NetworkInteracting
    private let pairingStorage: WCPairingStorage
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
         messageFormatter: SIWEMessageFormatting,
         pairingStorage: WCPairingStorage) {
        self.networkingInteractor = networkingInteractor
        self.logger = logger
        self.rpcHistory = rpcHistory
        self.signatureVerifier = signatureVerifier
        self.messageFormatter = messageFormatter
        self.pairingStorage = pairingStorage
        subscribeForResponse()
    }

    private func subscribeForResponse() {
        networkingInteractor.responsePublisher.sink { [unowned self] subscriptionPayload in
            let response = subscriptionPayload.response
            guard
                let requestId = response.id,
                let request = rpcHistory.get(recordId: requestId)?.request,
                let requestParams = request.params, request.method == "wc_authRequest"
            else { return }

            activatePairingIfNeeded(id: requestId)
            networkingInteractor.unsubscribe(topic: subscriptionPayload.topic)

            if let errorResponse = response.error,
               let error = AuthError(code: errorResponse.code) {
                onResponse?(requestId, .failure(error))
                return
            }

            guard
                let cacao = try? response.result?.get(Cacao.self),
                let address = try? DIDPKH(iss: cacao.payload.iss).account.address,
                let message = try? messageFormatter.formatMessage(from: cacao.payload)
            else { self.onResponse?(requestId, .failure(.malformedResponseParams)); return }

            guard let requestPayload = try? requestParams.get(AuthRequestParams.self)
            else { self.onResponse?(requestId, .failure(.malformedRequestParams)); return }

            guard messageFormatter.formatMessage(from: requestPayload.payloadParams, address: address) == message
            else { self.onResponse?(requestId, .failure(.messageCompromised)); return }

            guard let _ = try? signatureVerifier.verify(signature: cacao.signature, message: message, address: address)
            else { self.onResponse?(requestId, .failure(.signatureVerificationFailed)); return }

            onResponse?(requestId, .success(cacao))

        }.store(in: &publishers)
    }

    private func activatePairingIfNeeded(id: RPCID) {
        guard let record = rpcHistory.get(recordId: id) else { return }
        let pairingTopic = record.topic
        guard var pairing = pairingStorage.getPairing(forTopic: pairingTopic) else { return }
        if !pairing.active {
            pairing.activate()
        } else {
            try? pairing.updateExpiry()
        }
    }
}
