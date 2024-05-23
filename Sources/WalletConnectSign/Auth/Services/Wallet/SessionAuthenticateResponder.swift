import Foundation
import Combine

actor SessionAuthenticateResponder {

    private let networkingInteractor: NetworkInteracting
    private let kms: KeyManagementService
    private let verifyContextStore: CodableStore<VerifyContext>
    private let logger: ConsoleLogging
    private let walletErrorResponder: WalletErrorResponder
    private let pairingRegisterer: PairingRegisterer
    private let metadata: AppMetadata
    private let util: ApproveSessionAuthenticateUtil

    init(
        networkingInteractor: NetworkInteracting,
        logger: ConsoleLogging,
        kms: KeyManagementService,
        verifyContextStore: CodableStore<VerifyContext>,
        walletErrorResponder: WalletErrorResponder,
        pairingRegisterer: PairingRegisterer,
        metadata: AppMetadata,
        approveSessionAuthenticateUtil: ApproveSessionAuthenticateUtil
    ) {
        self.networkingInteractor = networkingInteractor
        self.logger = logger
        self.kms = kms
        self.verifyContextStore = verifyContextStore
        self.walletErrorResponder = walletErrorResponder
        self.pairingRegisterer = pairingRegisterer
        self.metadata = metadata
        self.util = approveSessionAuthenticateUtil
    }

    func respond(requestId: RPCID, auths: [Cacao]) async throws -> Session? {
        try await util.recoverAndVerifySignature(cacaos: auths)
        let (sessionAuthenticateRequestParams, pairingTopic) = try util.getsessionAuthenticateRequestParams(requestId: requestId)
        let (responseTopic, responseKeys) = try util.generateAgreementKeys(requestParams: sessionAuthenticateRequestParams)


        try kms.setAgreementSecret(responseKeys, topic: responseTopic)

        let peerParticipant = sessionAuthenticateRequestParams.requester

        let sessionSelfPubKey = try kms.createX25519KeyPair()
        let sessionSelfPubKeyHex = sessionSelfPubKey.hexRepresentation
        let sessionKeys = try kms.performKeyAgreement(selfPublicKey: sessionSelfPubKey, peerPublicKey: peerParticipant.publicKey)

        let sessionTopic = sessionKeys.derivedTopic()
        try kms.setAgreementSecret(sessionKeys, topic: sessionTopic)

        let selfParticipant = Participant(publicKey: sessionSelfPubKeyHex, metadata: metadata)
        let responseParams = SessionAuthenticateResponseParams(responder: selfParticipant, cacaos: auths)

        let response = RPCResponse(id: requestId, result: responseParams)
        
        try await networkingInteractor.respond(
            topic: responseTopic,
            response: response,
            protocolMethod: SessionAuthenticatedProtocolMethod.responseApprove(),
            envelopeType: .type1(pubKey: responseKeys.publicKey.rawRepresentation)
        )


        let session = try util.createSession(
            response: responseParams,
            pairingTopic: pairingTopic,
            request: sessionAuthenticateRequestParams,
            sessionTopic: sessionTopic,
            transportType: .relay
        )

        pairingRegisterer.activate(
            pairingTopic: pairingTopic,
            peerMetadata: sessionAuthenticateRequestParams.requester.metadata
        )

        verifyContextStore.delete(forKey: requestId.string)
        
        return session
    }

    func respondError(requestId: RPCID) async throws {
        try await walletErrorResponder.respondError(AuthError.userRejeted, requestId: requestId)
        verifyContextStore.delete(forKey: requestId.string)
    }
}


