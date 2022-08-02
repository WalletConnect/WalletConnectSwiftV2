import Combine
import Foundation
import WalletConnectUtils
import WalletConnectKMS

class AuthRequestSubscriber {
    private let networkingInteractor: NetworkInteracting
    private let kms: KeyManagementService
    private let logger: ConsoleLogging
    private var publishers = [AnyCancellable]()
    private let messageFormatter: SIWEMessageFormatting
    var onRequest: ((_ id: Int64, _ message: String)->())?

    init(networkingInteractor: NetworkInteracting,
         logger: ConsoleLogging,
         messageFormatter: SIWEMessageFormatting) {
        self.networkingInteractor = networkingInteractor
        self.logger = logger
        self.messageFormatter = messageFormatter
        subscribeForRequest()
    }

    private func subscribeForRequest() {
        networkingInteractor.requestPublisher.sink { [unowned self] subscriptionPayload in
            guard subscriptionPayload.request.method == "wc_authRequest" else { return }
            guard let authRequestParams = try? subscriptionPayload.request.params?.get(AuthRequestParams.self) else {
                logger.debug("Malformed auth request params")
                return
            }
            do {
                let message = try messageFormatter.formatMessage(from: authRequestParams)
                guard let requestId = subscriptionPayload.request.id?.right else { return }
                try setKeysForResponse(authRequestParams: authRequestParams)
                onRequest?(requestId, message)
            } catch {
                logger.debug(error)
            }
        }.store(in: &publishers)
    }

    private func setKeysForResponse(authRequestParams: AuthRequestParams) throws  {
        let peerPubKey = authRequestParams.requester.publicKey
        let responseTopic = peerPubKey.rawRepresentation.sha256().toHexString()
        let selfPubKey = try kms.createX25519KeyPair()
        let agreementKeys = try kms.performKeyAgreement(selfPublicKey: selfPubKey, peerPublicKey: peerPubKey)
        try kms.setAgreementSecret(agreementKeys, topic: responseTopic)
    }
}
