import Foundation
import Combine

class AuthResponseSubscriber {
    private let networkingInteractor: NetworkInteracting
    private let linkEnvelopesDispatcher: LinkEnvelopesDispatcher
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
    private let linkModeLinksStore: CodableStore<Bool>
    private let supportLinkMode: Bool
    private let pairingStore: WCPairingStorage
    private let eventsClient: EventsClientProtocol

    init(networkingInteractor: NetworkInteracting,
         logger: ConsoleLogging,
         rpcHistory: RPCHistory,
         signatureVerifier: MessageVerifier,
         pairingRegisterer: PairingRegisterer,
         kms: KeyManagementServiceProtocol,
         sessionStore: WCSessionStorage,
         messageFormatter: SIWEFromCacaoFormatting,
         sessionNamespaceBuilder: SessionNamespaceBuilder,
         authResponseTopicRecordsStore: CodableStore<AuthResponseTopicRecord>,
         linkEnvelopesDispatcher: LinkEnvelopesDispatcher,
         linkModeLinksStore: CodableStore<Bool>,
         pairingStore: WCPairingStorage,
         supportLinkMode: Bool,
         eventsClient: EventsClientProtocol
    ) {
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
        self.linkEnvelopesDispatcher = linkEnvelopesDispatcher
        self.linkModeLinksStore = linkModeLinksStore
        self.supportLinkMode = supportLinkMode
        self.pairingStore = pairingStore
        self.eventsClient = eventsClient

        subscribeForResponse()
        subscribeForLinkResponse()
    }

    private func subscribeForResponse() {
        networkingInteractor
            .responseErrorSubscription(on: SessionAuthenticatedProtocolMethod.responseApprove())
            .sink { [unowned self] (payload: ResponseSubscriptionErrorPayload<SessionAuthenticateRequestParams>) in
                guard let error = AuthError(code: payload.error.code) else { return }
                Task { removePairing(pairingTopic: payload.topic) }
                authResponsePublisherSubject.send((payload.id, .failure(error)))
            }.store(in: &publishers)

        networkingInteractor
            .responseSubscription(on: SessionAuthenticatedProtocolMethod.responseApprove())
            .sink { [unowned self] (payload: ResponseSubscriptionPayload<SessionAuthenticateRequestParams, SessionAuthenticateResponseParams>)  in

                let transportType = getTransportTypeUpgradeIfPossible(peerMetadata: payload.response.responder.metadata, requestId: payload.id)

                let pairingTopic = payload.topic
                removeResponseTopicRecord(responseTopic: payload.topic)
                Task { removePairing(pairingTopic: pairingTopic) }

                let requestId = payload.id
                let cacaos = payload.response.cacaos

                Task {
                    do {
                        try await recoverAndVerifySignature(cacaos: cacaos)
                    } catch {
                        authResponsePublisherSubject.send((requestId, .failure(error as! AuthError)))
                        return
                    }
                    let session = try createSession(from: payload.response, selfParticipant: payload.request.requester, pairingTopic: pairingTopic, transportType: transportType)

                    authResponsePublisherSubject.send((requestId, .success((session, cacaos))))
                }

            }.store(in: &publishers)
    }

    private func subscribeForLinkResponse() {
        linkEnvelopesDispatcher.responseErrorSubscription(on: SessionAuthenticatedProtocolMethod.responseApprove())
            .sink { [unowned self] (payload: ResponseSubscriptionErrorPayload<SessionAuthenticateRequestParams>) in
                Task { eventsClient.saveMessageEvent(.sessionAuthenticateLinkModeResponseRejectReceived(payload.id)) }
                guard let error = AuthError(code: payload.error.code) else { return }
                authResponsePublisherSubject.send((payload.id, .failure(error)))
            }.store(in: &publishers)

        linkEnvelopesDispatcher.responseSubscription(on: SessionAuthenticatedProtocolMethod.responseApprove())
            .sink { [unowned self] (payload: ResponseSubscriptionPayload<SessionAuthenticateRequestParams, SessionAuthenticateResponseParams>)  in

                Task(priority: .low) { eventsClient.saveMessageEvent(.sessionAuthenticateLinkModeResponseApproveReceived(payload.id)) }

                _ = getTransportTypeUpgradeIfPossible(peerMetadata: payload.response.responder.metadata, requestId: payload.id)

                let pairingTopic = payload.topic
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
                    let session = try createSession(from: payload.response, selfParticipant: payload.request.requester, pairingTopic: pairingTopic, transportType: .linkMode)

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

    private func getTransportTypeUpgradeIfPossible(peerMetadata: AppMetadata, requestId: RPCID) -> WCSession.TransportType {
//        upgrade to link mode only if dapp requested universallink because dapp may not be prepared for handling a response - add this to doc]

        if let peerRedirect = peerMetadata.redirect,
           let peerLinkMode = peerRedirect.linkMode,
            peerLinkMode == true,
           let universalLink = peerRedirect.universal,
           supportLinkMode {
            linkModeLinksStore.set(true, forKey: universalLink)
            return .linkMode
        } else {
            return .relay
        }
    }

    private func createSession(
        from response: SessionAuthenticateResponseParams,
        selfParticipant: Participant,
        pairingTopic: String,
        transportType: WCSession.TransportType
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
            acknowledged: true,
            transportType: transportType,
            verifyContext: nil
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

    private func removePairing(pairingTopic: String) {
        pairingStore.delete(topic: pairingTopic)
        kms.deleteSymmetricKey(for: pairingTopic)
    }
}

