import Foundation
import Combine
import JSONRPC
import WalletConnectNetworking
import WalletConnectUtils
import WalletConnectKMS
import WalletConnectPairing

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
            .sink { [unowned self] (topic, request) in
                let params = try! request.params!.get(AuthRequestParams.self)
                logger.debug("WalletRequestSubscriber: Received request")
                guard let message = messageFormatter.formatMessage(from: params.payloadParams, address: address) else {
                    Task(priority: .high) {
                        try? await walletErrorResponder.respondError(AuthError.malformedRequestParams, requestId: request.id!)
                    }
                    return
                }
                onRequest?(.init(id: request.id!, message: message))
            }.store(in: &publishers)
    }
}

