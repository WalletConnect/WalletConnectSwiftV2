import Foundation
import Combine

class WalletRequestSubscriber {
    private let networkingInteractor: NetworkInteracting
    private let logger: ConsoleLogging
    private let kms: KeyManagementServiceProtocol
    private let address: String?
    private var publishers = [AnyCancellable]()
    private let messageFormatter: SIWEMessageFormatting
    private let walletErrorResponder: WalletErrorResponder
    private let pairingRegisterer: PairingRegisterer
    var onRequest: ((AuthRequest) -> Void)?

    init(networkingInteractor: NetworkInteracting,
         logger: ConsoleLogging,
         kms: KeyManagementServiceProtocol,
         messageFormatter: SIWEMessageFormatting,
         address: String?,
         walletErrorResponder: WalletErrorResponder,
         pairingRegisterer: PairingRegisterer) {
        self.networkingInteractor = networkingInteractor
        self.logger = logger
        self.kms = kms
        self.address = address
        self.messageFormatter = messageFormatter
        self.walletErrorResponder = walletErrorResponder
        self.pairingRegisterer = pairingRegisterer
        subscribeForRequest()
    }

    private func subscribeForRequest() {
        guard let address = address else { return }

        pairingRegisterer.register(method: AuthRequestProtocolMethod())
            .sink { [unowned self] (payload: RequestSubscriptionPayload<AuthRequestParams>) in
                logger.debug("WalletRequestSubscriber: Received request")
                guard let message = messageFormatter.formatMessage(from: payload.request.payloadParams, address: address) else {
                    Task(priority: .high) {
                        try? await walletErrorResponder.respondError(AuthError.malformedRequestParams, requestId: payload.id)
                    }
                    return
                }
                pairingRegisterer.activate(pairingTopic: payload.topic)
                onRequest?(.init(id: payload.id, message: message))
            }.store(in: &publishers)
    }
}
