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
    private let pairingStore: WCPairingStorage

    init(
        networkingInteractor: NetworkInteracting,
        logger: ConsoleLogging,
        kms: KeyManagementService,
        verifyContextStore: CodableStore<VerifyContext>,
        walletErrorResponder: WalletErrorResponder,
        pairingRegisterer: PairingRegisterer,
        metadata: AppMetadata,
        approveSessionAuthenticateUtil: ApproveSessionAuthenticateUtil,
        eventsClient: EventsClientProtocol,
        pairingStore: WCPairingStorage
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
        self.pairingStore = pairingStore
    }

    func respond(requestId: RPCID, auths: [Cacao]) async throws -> Session? {
        eventsClient.saveTraceEvent(SessionAuthenticateTraceEvents.signatureVerificationStarted)
        do {
            try await util.recoverAndVerifySignature(cacaos: auths)
            eventsClient.saveTraceEvent(SessionAuthenticateTraceEvents.signatureVerificationSuccess)
        } catch {
            eventsClient.saveTraceEvent(SessionAuthenticateErrorEvents.signatureVerificationFailed)
            throw error
        }

        let sessionAuthenticateRequestParams: SessionAuthenticateRequestParams
        let pairingTopic: String

        do {
            (sessionAuthenticateRequestParams, pairingTopic) = try util.getsessionAuthenticateRequestParams(requestId: requestId)
            eventsClient.saveTraceEvent(SessionAuthenticateTraceEvents.requestParamsRetrieved)
        } catch {
            eventsClient.saveTraceEvent(SessionAuthenticateErrorEvents.requestParamsRetrievalFailed)
            throw error
        }

        let responseTopic: String
        let responseKeys: AgreementKeys

        do {
            (responseTopic, responseKeys) = try util.generateAgreementKeys(requestParams: sessionAuthenticateRequestParams)
            eventsClient.saveTraceEvent(SessionAuthenticateTraceEvents.agreementKeysGenerated)
        } catch {
            eventsClient.saveTraceEvent(SessionAuthenticateErrorEvents.agreementKeysGenerationFailed)
            throw error
        }

        do {
            try kms.setAgreementSecret(responseKeys, topic: responseTopic)
            eventsClient.saveTraceEvent(SessionAuthenticateTraceEvents.agreementSecretSet)
        } catch {
            eventsClient.saveTraceEvent(SessionAuthenticateErrorEvents.agreementSecretSetFailed)
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
            eventsClient.saveTraceEvent(SessionAuthenticateTraceEvents.sessionKeysGenerated)
        } catch {
            eventsClient.saveTraceEvent(SessionAuthenticateErrorEvents.sessionKeysGenerationFailed)
            throw error
        }

        let sessionTopic = sessionKeys.derivedTopic()
        do {
            try kms.setAgreementSecret(sessionKeys, topic: sessionTopic)
            eventsClient.saveTraceEvent(SessionAuthenticateTraceEvents.sessionSecretSet)
        } catch {
            eventsClient.saveTraceEvent(SessionAuthenticateErrorEvents.sessionSecretSetFailed)
            throw error
        }

        let selfParticipant = Participant(publicKey: sessionSelfPubKeyHex, metadata: metadata)
        let responseParams = SessionAuthenticateResponseParams(responder: selfParticipant, cacaos: auths)
        eventsClient.saveTraceEvent(SessionAuthenticateTraceEvents.responseParamsCreated)

        let response = RPCResponse(id: requestId, result: responseParams)

        do {
            try await networkingInteractor.respond(
                topic: responseTopic,
                response: response,
                protocolMethod: SessionAuthenticatedProtocolMethod.responseApprove(),
                envelopeType: .type1(pubKey: responseKeys.publicKey.rawRepresentation)
            )
            Task {
                removePairing(pairingTopic: pairingTopic)
            }
            eventsClient.saveTraceEvent(SessionAuthenticateTraceEvents.responseSent)
        } catch {
            eventsClient.saveTraceEvent(SessionAuthenticateErrorEvents.responseSendFailed)
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
            verifyContextStore.delete(forKey: requestId.string)
            return session
        } catch {
            eventsClient.saveTraceEvent(SessionAuthenticateErrorEvents.sessionCreationFailed)
            throw error
        }
    }

    func respondError(requestId: RPCID) async throws {
        let pairingTopic = try? util.getHistoryRecord(requestId: requestId).topic
        do {
            let _ = try await walletErrorResponder.respondError(AuthError.userRejeted, requestId: requestId)
            Task {
                if let pairingTopic = pairingTopic {
                    removePairing(pairingTopic: pairingTopic)
                }
            }
        } catch {
            throw error
        }
        verifyContextStore.delete(forKey: requestId.string)
    }

    private func removePairing(pairingTopic: String) {
        pairingStore.delete(topic: pairingTopic)
        networkingInteractor.unsubscribe(topic: pairingTopic)
        kms.deleteSymmetricKey(for: pairingTopic)
    }
}
