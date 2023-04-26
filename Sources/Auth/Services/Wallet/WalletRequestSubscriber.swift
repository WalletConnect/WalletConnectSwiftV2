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
    var onRequest: (((AuthRequest, AuthContext?)) -> Void)?
    
    init(
        networkingInteractor: NetworkInteracting,
        logger: ConsoleLogging,
        kms: KeyManagementServiceProtocol,
        walletErrorResponder: WalletErrorResponder,
        pairingRegisterer: PairingRegisterer) {
            self.networkingInteractor = networkingInteractor
            self.logger = logger
            self.kms = kms
            self.walletErrorResponder = walletErrorResponder
            self.pairingRegisterer = pairingRegisterer
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
                
                if #available(iOS 14.0, *) {
                    if let rawRequest = payload.rawRequest {
                        let verifyUrl = "https://verify.walletconnect.com"
                        let verifyClient = try? VerifyClientFactory.create(verifyHost: verifyUrl)
                        let attestationId = rawRequest.rawRepresentation.sha256().toHexString()
                        
                        Task(priority: .high) {
                            let origin = try? await verifyClient?.registerAssertion(attestationId: attestationId)
                            let authContext = AuthContext(
                                origin: origin,
                                validation: (origin == payload.request.payloadParams.domain) ? .valid : (origin == nil ? .unknown : .invalid),
                                verifyUrl: verifyUrl
                            )
                            onRequest?((request, authContext))
                        }
                    }
                } else {
                    onRequest?((request, nil))
                }
                
            }.store(in: &publishers)
    }
}
