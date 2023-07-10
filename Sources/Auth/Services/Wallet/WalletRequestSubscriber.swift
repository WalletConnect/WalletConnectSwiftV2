import Foundation
import Combine

class WalletRequestSubscriber {
    private let networkingInteractor: NetworkInteracting
    private let logger: ConsoleLogging
    private let kms: KeyManagementServiceProtocol
    private var publishers = [AnyCancellable]()
    private let walletErrorResponder: WalletErrorResponder
    private let pairingRegisterer: PairingRegisterer
    private let verifyClient: VerifyClientProtocol
    private let verifyContextStore: CodableStore<VerifyContext>

    var onRequest: (((request: AuthRequest, context: VerifyContext?)) -> Void)?
    
    init(
        networkingInteractor: NetworkInteracting,
        logger: ConsoleLogging,
        kms: KeyManagementServiceProtocol,
        walletErrorResponder: WalletErrorResponder,
        pairingRegisterer: PairingRegisterer,
        verifyClient: VerifyClientProtocol,
        verifyContextStore: CodableStore<VerifyContext>
    ) {
        self.networkingInteractor = networkingInteractor
        self.logger = logger
        self.kms = kms
        self.walletErrorResponder = walletErrorResponder
        self.pairingRegisterer = pairingRegisterer
        self.verifyClient = verifyClient
        self.verifyContextStore = verifyContextStore
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
                
                let request = AuthRequest(id: payload.id, topic: payload.topic, payload: payload.request.payloadParams)
                
                Task(priority: .high) {
                    let assertionId = payload.decryptedPayload.sha256().toHexString()
                    do {
                        let origin = try await verifyClient.verifyOrigin(assertionId: assertionId)
                        let verifyContext = verifyClient.createVerifyContext(
                            origin: origin,
                            domain: payload.request.payloadParams.domain
                        )
                        verifyContextStore.set(verifyContext, forKey: request.id.string)
                        onRequest?((request, verifyContext))
                    } catch {
                        onRequest?((request, nil))
                        return
                    }
                }
            }.store(in: &publishers)
    }
}
