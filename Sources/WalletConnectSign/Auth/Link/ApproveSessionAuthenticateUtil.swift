import Foundation

class ApproveSessionAuthenticateUtil {
    enum Errors: Error {
        case recordForIdNotFound
        case malformedAuthRequestParams
    }

    private let kms: KeyManagementService
    private let messageFormatter: SIWEFromCacaoFormatting
    private let signatureVerifier: MessageVerifier
    private let networkingInteractor: NetworkInteracting
    private let rpcHistory: RPCHistory
    private let logger: ConsoleLogging
    private let sessionStore: WCSessionStorage
    private let sessionNamespaceBuilder: SessionNamespaceBuilder
    private let verifyContextStore: CodableStore<VerifyContext>
    private let verifyClient: VerifyClientProtocol

    init(
        logger: ConsoleLogging,
        kms: KeyManagementService,
        rpcHistory: RPCHistory,
        signatureVerifier: MessageVerifier,
        messageFormatter: SIWEFromCacaoFormatting,
        sessionStore: WCSessionStorage,
        sessionNamespaceBuilder: SessionNamespaceBuilder,
        networkingInteractor: NetworkInteracting,
        verifyContextStore: CodableStore<VerifyContext>,
        verifyClient: VerifyClientProtocol
    ) {
        self.logger = logger
        self.kms = kms
        self.rpcHistory = rpcHistory
        self.sessionStore = sessionStore
        self.sessionNamespaceBuilder = sessionNamespaceBuilder
        self.signatureVerifier = signatureVerifier
        self.messageFormatter = messageFormatter
        self.networkingInteractor = networkingInteractor
        self.verifyContextStore = verifyContextStore
        self.verifyClient = verifyClient
    }

    func getsessionAuthenticateRequestParams(requestId: RPCID) throws -> (request: SessionAuthenticateRequestParams, topic: String) {
        let record = try getHistoryRecord(requestId: requestId)

        let request = record.request
        guard let authRequestParams = try request.params?.get(SessionAuthenticateRequestParams.self)
        else { throw Errors.malformedAuthRequestParams }

        return (request: authRequestParams, topic: record.topic)
    }

    func getHistoryRecord(requestId: RPCID) throws -> RPCHistory.Record {
        guard let record = rpcHistory.get(recordId: requestId)
        else { throw Errors.recordForIdNotFound }
        return record
    }


    func generateAgreementKeys(requestParams: SessionAuthenticateRequestParams) throws -> (topic: String, keys: AgreementKeys) {
        let peerPubKey = try AgreementPublicKey(hex: requestParams.requester.publicKey)
        let topic = peerPubKey.rawRepresentation.sha256().toHexString()
        let selfPubKey = try kms.createX25519KeyPair()
        let keys = try kms.performKeyAgreement(selfPublicKey: selfPubKey, peerPublicKey: peerPubKey.hexRepresentation)
        return (topic, keys)
    }

    func createSession(
        response: SessionAuthenticateResponseParams,
        pairingTopic: String,
        request: SessionAuthenticateRequestParams,
        sessionTopic: String,
        transportType: WCSession.TransportType,
        verifyContext: VerifyContext
    ) throws -> Session? {


        let selfParticipant = response.responder
        let peerParticipant = request.requester

        let expiry = Date()
            .addingTimeInterval(TimeInterval(WCSession.defaultTimeToLive))
            .timeIntervalSince1970

        let relay = RelayProtocolOptions(protocol: "irn", data: nil)

        guard let sessionNamespaces = try? sessionNamespaceBuilder.buildSessionNamespaces(cacaos: response.cacaos) else {
            logger.debug("Cacao doesn't contain valid Sign Recap, session won't be created")
            return nil
        }

        let settleParams = SessionType.SettleParams(
            relay: relay,
            controller: selfParticipant,
            namespaces: sessionNamespaces,
            sessionProperties: nil,
            expiry: Int64(expiry)
        )

        let session = WCSession(
            topic: sessionTopic,
            pairingTopic: pairingTopic,
            timestamp: Date(),
            selfParticipant: selfParticipant,
            peerParticipant: peerParticipant,
            settleParams: settleParams,
            requiredNamespaces: [:],
            acknowledged: true,
            transportType: transportType,
            verifyContext: verifyContext
        )
        logger.debug("created a session with topic: \(sessionTopic)")

        sessionStore.setSession(session)
        Task {
            logger.debug("subscribing to session topic: \(sessionTopic)")
            try await networkingInteractor.subscribe(topic: sessionTopic)
        }

        return session.publicRepresentation()
    }


    func getVerifyContext(requestId: RPCID, domain: String) -> VerifyContext {
        guard let context = try? verifyContextStore.get(key: requestId.string) else {
            return verifyClient.createVerifyContext(origin: nil, domain: domain, isScam: false, isVerified: nil)
        }
        return context
    }


    func recoverAndVerifySignature(cacaos: [Cacao]) async throws {
        try await cacaos.asyncForEach { [unowned self] cacao in
            guard
                let account = try? DIDPKH(did: cacao.p.iss).account,
                let message = try? messageFormatter.formatMessage(from: cacao.p, includeRecapInTheStatement: true)
            else {
                throw AuthError.malformedResponseParams
            }
            do {
                try await signatureVerifier.verify(
                    signature: cacao.s,
                    message: message,
                    account: account
                )
            } catch {
                logger.error("Signature verification failed with: \(error.localizedDescription)")
                throw AuthError.signatureVerificationFailed
            }
        }
    }
}
extension ApproveSessionAuthenticateUtil.Errors: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .recordForIdNotFound:
            return NSLocalizedString("The record for the specified ID was not found.", comment: "Record Not Found Error")
        case .malformedAuthRequestParams:
            return NSLocalizedString("The authentication request parameters are malformed.", comment: "Malformed Auth Request Params Error")
        }
    }
}
