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
    private let eventsClient: EventsClientProtocol

    init(
        networkingInteractor: NetworkInteracting,
        logger: ConsoleLogging,
        kms: KeyManagementService,
        verifyContextStore: CodableStore<VerifyContext>,
        walletErrorResponder: WalletErrorResponder,
        pairingRegisterer: PairingRegisterer,
        metadata: AppMetadata,
        approveSessionAuthenticateUtil: ApproveSessionAuthenticateUtil,
        eventsClient: EventsClientProtocol
    ) {
        self.networkingInteractor = networkingInteractor
        self.logger = logger
        self.kms = kms
        self.verifyContextStore = verifyContextStore
        self.walletErrorResponder = walletErrorResponder
        self.pairingRegisterer = pairingRegisterer
        self.metadata = metadata
        self.util = approveSessionAuthenticateUtil
        self.eventsClient = eventsClient
    }

    func respond(requestId: RPCID, auths: [Cacao]) async throws -> Session? {
        eventsClient.saveEvent(SessionAuthenticateTraceEvents.signatureVerificationStarted)
        do {
            try await util.recoverAndVerifySignature(cacaos: auths)
            eventsClient.saveEvent(SessionAuthenticateTraceEvents.signatureVerificationSuccess)
        } catch {
            eventsClient.saveEvent(SessionAuthenticateErrorEvents.signatureVerificationFailed)
            throw error
        }

        let sessionAuthenticateRequestParams: SessionAuthenticateRequestParams
        let pairingTopic: String

        do {
            (sessionAuthenticateRequestParams, pairingTopic) = try util.getsessionAuthenticateRequestParams(requestId: requestId)
            eventsClient.saveEvent(SessionAuthenticateTraceEvents.requestParamsRetrieved)
        } catch {
            eventsClient.saveEvent(SessionAuthenticateErrorEvents.requestParamsRetrievalFailed)
            throw error
        }

        let responseTopic: String
        let responseKeys: AgreementKeys

        do {
            (responseTopic, responseKeys) = try util.generateAgreementKeys(requestParams: sessionAuthenticateRequestParams)
            eventsClient.saveEvent(SessionAuthenticateTraceEvents.agreementKeysGenerated)
        } catch {
            eventsClient.saveEvent(SessionAuthenticateErrorEvents.agreementKeysGenerationFailed)
            throw error
        }

        do {
            try kms.setAgreementSecret(responseKeys, topic: responseTopic)
            eventsClient.saveEvent(SessionAuthenticateTraceEvents.agreementSecretSet)
        } catch {
            eventsClient.saveEvent(SessionAuthenticateErrorEvents.agreementSecretSetFailed)
            throw error
        }

        let peerParticipant = sessionAuthenticateRequestParams.requester

        let sessionSelfPubKey: AgreementPublicKey
        let sessionSelfPubKeyHex: String
        let sessionKeys: AgreementKeys

        do {
            sessionSelfPubKey = try kms.createX25519KeyPair()
            sessionSelfPubKeyHex = sessionSelfPubKey.hexRepresentation
            sessionKeys = try kms.performKeyAgreement(selfPublicKey: sessionSelfPubKey, peerPublicKey: peerParticipant.publicKey)
            eventsClient.saveEvent(SessionAuthenticateTraceEvents.sessionKeysGenerated)
        } catch {
            eventsClient.saveEvent(SessionAuthenticateErrorEvents.sessionKeysGenerationFailed)
            throw error
        }

        let sessionTopic = sessionKeys.derivedTopic()
        do {
            try kms.setAgreementSecret(sessionKeys, topic: sessionTopic)
            eventsClient.saveEvent(SessionAuthenticateTraceEvents.sessionSecretSet)
        } catch {
            eventsClient.saveEvent(SessionAuthenticateErrorEvents.sessionSecretSetFailed)
            throw error
        }

        let selfParticipant = Participant(publicKey: sessionSelfPubKeyHex, metadata: metadata)
        let responseParams = SessionAuthenticateResponseParams(responder: selfParticipant, cacaos: auths)
        eventsClient.saveEvent(SessionAuthenticateTraceEvents.responseParamsCreated)

        let response = RPCResponse(id: requestId, result: responseParams)

        do {
            try await networkingInteractor.respond(
                topic: responseTopic,
                response: response,
                protocolMethod: SessionAuthenticatedProtocolMethod.responseApprove(),
                envelopeType: .type1(pubKey: responseKeys.publicKey.rawRepresentation)
            )
            eventsClient.saveEvent(SessionAuthenticateTraceEvents.responseSent)
        } catch {
            eventsClient.saveEvent(SessionAuthenticateErrorEvents.responseSendFailed)
            throw error
        }

        do {
            let session = try util.createSession(
                response: responseParams,
                pairingTopic: pairingTopic,
                request: sessionAuthenticateRequestParams,
                sessionTopic: sessionTopic,
                transportType: .relay,
                verifyContext: util.getVerifyContext(requestId: requestId, domain: sessionAuthenticateRequestParams.requester.metadata.url)
            )
            pairingRegisterer.activate(
                pairingTopic: pairingTopic,
                peerMetadata: sessionAuthenticateRequestParams.requester.metadata
            )
            verifyContextStore.delete(forKey: requestId.string)
            return session
        } catch {
            eventsClient.saveEvent(SessionAuthenticateErrorEvents.sessionCreationFailed)
            throw error
        }
    }

    func respondError(requestId: RPCID) async throws {
        do {
            try await walletErrorResponder.respondError(AuthError.userRejeted, requestId: requestId)
        } catch {
            throw error
        }
        verifyContextStore.delete(forKey: requestId.string)
    }
}
