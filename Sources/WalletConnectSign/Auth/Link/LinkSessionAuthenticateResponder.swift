import Foundation
import Combine

actor LinkSessionAuthenticateResponder {
    enum Errors: Error {
        case missingPeerUniversalLink
    }
    private let linkEnvelopesDispatcher: LinkEnvelopesDispatcher
    private let kms: KeyManagementService
    private let logger: ConsoleLogging
    private let metadata: AppMetadata
    private let util: ApproveSessionAuthenticateUtil
    private let walletErrorResponder: WalletErrorResponder
    private let verifyContextStore: CodableStore<VerifyContext>
    private let eventsClient: EventsClientProtocol

    init(
        linkEnvelopesDispatcher: LinkEnvelopesDispatcher,
        logger: ConsoleLogging,
        kms: KeyManagementService,
        metadata: AppMetadata,
        approveSessionAuthenticateUtil: ApproveSessionAuthenticateUtil,
        walletErrorResponder: WalletErrorResponder,
        verifyContextStore: CodableStore<VerifyContext>,
        eventsClient: EventsClientProtocol
    ) {
        self.linkEnvelopesDispatcher = linkEnvelopesDispatcher
        self.logger = logger
        self.verifyContextStore = verifyContextStore
        self.kms = kms
        self.metadata = metadata
        self.util = approveSessionAuthenticateUtil
        self.walletErrorResponder = walletErrorResponder
        self.eventsClient = eventsClient
    }

    func respond(requestId: RPCID, auths: [Cacao]) async throws -> (Session?, String) {
        logger.debug("responding session authenticate")
        try await util.recoverAndVerifySignature(cacaos: auths)
        let (sessionAuthenticateRequestParams, pairingTopic) = try util.getsessionAuthenticateRequestParams(requestId: requestId)
        let (responseTopic, responseKeys) = try util.generateAgreementKeys(requestParams: sessionAuthenticateRequestParams)

        let peerParticipant = sessionAuthenticateRequestParams.requester
        guard let peerUniversalLink = peerParticipant.metadata.redirect?.universal else {
            throw Errors.missingPeerUniversalLink
        }

        try kms.setAgreementSecret(responseKeys, topic: responseTopic)


        let sessionSelfPubKey = try kms.createX25519KeyPair()
        let sessionSelfPubKeyHex = sessionSelfPubKey.hexRepresentation
        let sessionKeys = try kms.performKeyAgreement(selfPublicKey: sessionSelfPubKey, peerPublicKey: peerParticipant.publicKey)

        let sessionTopic = sessionKeys.derivedTopic()
        try kms.setAgreementSecret(sessionKeys, topic: sessionTopic)

        let selfParticipant = Participant(publicKey: sessionSelfPubKeyHex, metadata: metadata)
        let responseParams = SessionAuthenticateResponseParams(responder: selfParticipant, cacaos: auths)

        let response = RPCResponse(id: requestId, result: responseParams)


        let url = try await linkEnvelopesDispatcher.respond(topic: responseTopic, response: response, peerUniversalLink: peerUniversalLink, envelopeType: .type1(pubKey: responseKeys.publicKey.rawRepresentation))

        Task(priority: .low) { eventsClient.saveMessageEvent(.sessionAuthenticateLinkModeResponseApproveSent(requestId)) }

        let session = try util.createSession(
            response: responseParams,
            pairingTopic: pairingTopic,
            request: sessionAuthenticateRequestParams,
            sessionTopic: sessionTopic,
            transportType: .linkMode,
            verifyContext: util.getVerifyContext(requestId: requestId, domain: sessionAuthenticateRequestParams.requester.metadata.url)
        )

        verifyContextStore.delete(forKey: requestId.string)

        return (session, url)
    }

    func respondError(requestId: RPCID) async throws {
        _ = try await walletErrorResponder.respondError(AuthError.userRejeted, requestId: requestId)
        verifyContextStore.delete(forKey: requestId.string)
    }

}


