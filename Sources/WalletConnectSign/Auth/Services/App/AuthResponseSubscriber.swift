import Foundation
import Combine

class AuthResponseSubscriber {
    private let networkingInteractor: NetworkInteracting
    private let logger: ConsoleLogging
    private let rpcHistory: RPCHistory
    private let signatureVerifier: MessageVerifier
    private let messageFormatter: SIWEFromCacaoFormatting
    private let pairingRegisterer: PairingRegisterer
    private var publishers = [AnyCancellable]()
    private let sessionStore: WCSessionStorage
    private let kms: KeyManagementServiceProtocol
    private let sessionNamespaceBuilder: SessionNamespaceBuilder
    private var authResponsePublisherSubject = PassthroughSubject<(id: RPCID, result: Result<(Session?, [Cacao]), AuthError>), Never>()
    public var authResponsePublisher: AnyPublisher<(id: RPCID, result: Result<(Session?, [Cacao]), AuthError>), Never> {
        authResponsePublisherSubject.eraseToAnyPublisher()
    }
    private let authResponseTopicRecordsStore: CodableStore<AuthResponseTopicRecord>

    init(networkingInteractor: NetworkInteracting,
         logger: ConsoleLogging,
         rpcHistory: RPCHistory,
         signatureVerifier: MessageVerifier,
         pairingRegisterer: PairingRegisterer,
         kms: KeyManagementServiceProtocol,
         sessionStore: WCSessionStorage,
         messageFormatter: SIWEFromCacaoFormatting,
         sessionNamespaceBuilder: SessionNamespaceBuilder,
         authResponseTopicRecordsStore: CodableStore<AuthResponseTopicRecord>) {
        self.networkingInteractor = networkingInteractor
        self.logger = logger
        self.rpcHistory = rpcHistory
        self.kms = kms
        self.sessionStore = sessionStore
        self.signatureVerifier = signatureVerifier
        self.messageFormatter = messageFormatter
        self.pairingRegisterer = pairingRegisterer
        self.sessionNamespaceBuilder = sessionNamespaceBuilder
        self.authResponseTopicRecordsStore = authResponseTopicRecordsStore
        subscribeForResponse()
    }

    private func subscribeForResponse() {
        networkingInteractor.responseErrorSubscription(on: SessionAuthenticatedProtocolMethod())
            .sink { [unowned self] (payload: ResponseSubscriptionErrorPayload<SessionAuthenticateRequestParams>) in
                guard let error = AuthError(code: payload.error.code) else { return }
                authResponsePublisherSubject.send((payload.id, .failure(error)))                
            }.store(in: &publishers)

        networkingInteractor.responseSubscription(on: SessionAuthenticatedProtocolMethod())
            .sink { [unowned self] (payload: ResponseSubscriptionPayload<SessionAuthenticateRequestParams, SessionAuthenticateResponseParams>)  in

                let pairingTopic = payload.topic
                pairingRegisterer.activate(pairingTopic: pairingTopic, peerMetadata: nil)
                removeResponseTopicRecord(responseTopic: payload.topic)

                let requestId = payload.id
                let cacaos = payload.response.cacaos

                Task {
                    do {
                        try await recoverAndVerifySignature(cacaos: cacaos)
                    } catch {
                        authResponsePublisherSubject.send((requestId, .failure(error as! AuthError)))
                        return
                    }
                    let session = try createSession(from: payload.response, selfParticipant: payload.request.requester, pairingTopic: pairingTopic)

                    authResponsePublisherSubject.send((requestId, .success((session, cacaos))))
                }

            }.store(in: &publishers)
    }

    private func recoverAndVerifySignature(cacaos: [Cacao]) async throws {
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

    private func createSession(
        from response: SessionAuthenticateResponseParams,
        selfParticipant: Participant,
        pairingTopic: String
    ) throws -> Session? {

        let selfPublicKey = try AgreementPublicKey(hex: selfParticipant.publicKey)
        let agreementKeys = try kms.performKeyAgreement(selfPublicKey: selfPublicKey, peerPublicKey: response.responder.publicKey)

        let peerParticipant = response.responder

        let sessionTopic = agreementKeys.derivedTopic()
        try kms.setAgreementSecret(agreementKeys, topic: sessionTopic)

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
            controller: peerParticipant,
            namespaces: sessionNamespaces,
            sessionProperties: nil,
            expiry: Int64(expiry)
        )

        let session = WCSession(
            topic: sessionTopic,
            pairingTopic: pairingTopic,
            timestamp: Date(),
            selfParticipant: selfParticipant,
            peerParticipant: response.responder,
            settleParams: settleParams,
            requiredNamespaces: [:],
            acknowledged: true
        )

        sessionStore.setSession(session)
        Task {
            logger.debug("subscribing to session topic: \(sessionTopic)")
            try await networkingInteractor.subscribe(topic: sessionTopic)
        }

        return session.publicRepresentation()
    }

    func removeResponseTopicRecord(responseTopic: String) {
        authResponseTopicRecordsStore.delete(forKey: responseTopic)
        networkingInteractor.unsubscribe(topic: responseTopic)
    }
}

