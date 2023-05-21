import Foundation
import Combine

class WalletRequestSubscriber {
    private let networkingInteractor: NetworkInteracting
    private let logger: ConsoleLogging
    private let kms: KeyManagementServiceProtocol
    private var publishers = [AnyCancellable]()
    private let walletErrorResponder: WalletErrorResponder
    private let pairingRegisterer: PairingRegisterer
    private let verifyClient: VerifyClient?
    var onRequest: (((request: AuthRequest, context: VerifyContext?)) -> Void)?
    
    init(
        networkingInteractor: NetworkInteracting,
        logger: ConsoleLogging,
        kms: KeyManagementServiceProtocol,
        walletErrorResponder: WalletErrorResponder,
        pairingRegisterer: PairingRegisterer,
        verifyClient: VerifyClient?
    ) {
        self.networkingInteractor = networkingInteractor
        self.logger = logger
        self.kms = kms
        self.walletErrorResponder = walletErrorResponder
        self.pairingRegisterer = pairingRegisterer
        self.verifyClient = verifyClient
        subscribeForRequest()
    }
    
    private func subscribeForRequest() {
        pairingRegisterer.register(method: AuthRequestProtocolMethod())
            .sink { [unowned self] (payload: RequestSubscriptionPayload<AuthRequestParams>) in
                logger.debug("WalletRequestSubscriber: Received request")
                
                pairingRegisterer.activate(
                    pairingTopic: payload.topic,
                    peerMetadata: payload.request.requester.metadata
                )
                
                let request = AuthRequest(id: payload.id, payload: payload.request.payloadParams)
                
                guard let verifyClient else {
                    onRequest?((request, nil))
                    return
                }
                Task(priority: .high) {
                    let assertionId = payload.decryptedPayload.sha256().toHexString()
                    let origin = try? await verifyClient.verifyOrigin(assertionId: assertionId)
                    let verifyContext = await verifyClient.createVerifyContext(
                        origin: origin,
                        domain: payload.request.payloadParams.domain
                    )
                    onRequest?((request, verifyContext))
                }
            }.store(in: &publishers)
    }
}
