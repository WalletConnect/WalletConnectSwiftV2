import Foundation
import Combine

import WalletConnectVerify

class WalletRequestSubscriber {
    private let networkingInteractor: NetworkInteracting
    private let logger: ConsoleLogging
    private let kms: KeyManagementServiceProtocol
    private var publishers = [AnyCancellable]()
    private let walletErrorResponder: WalletErrorResponder
    private let pairingRegisterer: PairingRegisterer
    private let verifyClient: VerifyClient?
    var onRequest: (((request: AuthRequest, context: AuthContext?)) -> Void)?
    
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
                
                if let rawRequest = payload.rawRequest, let verifyClient {
                    Task(priority: .high) {
                        let attestationId = rawRequest.rawRepresentation.sha256().toHexString()
                        let origin = try? await verifyClient.registerAssertion(attestationId: attestationId)
                        let authContext = await AuthContext(
                            origin: origin,
                            validation: (origin == payload.request.payloadParams.domain) ? .valid : (origin == nil ? .unknown : .invalid),
                            verifyUrl: verifyClient.verifyHost
                        )
                        onRequest?((request, authContext))
                    }
                } else {
                    onRequest?((request, nil))
                }
            }.store(in: &publishers)
    }
}
