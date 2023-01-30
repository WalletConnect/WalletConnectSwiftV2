import Foundation
import Combine

final class ApproveEngine {
    enum Errors: Error {
        case wrongRequestParams
        case relayNotFound
        case proposalPayloadsNotFound
        case pairingNotFound
        case sessionNotFound
        case agreementMissingOrInvalid
    }

    var onSessionProposal: ((Session.Proposal) -> Void)?
    var onSessionRejected: ((Session.Proposal, Reason) -> Void)?
    var onSessionSettle: ((Session) -> Void)?

    private let networkingInteractor: NetworkInteracting
    private let pairingStore: WCPairingStorage
    private let sessionStore: WCSessionStorage
    private let proposalPayloadsStore: CodableStore<RequestSubscriptionPayload<SessionType.ProposeParams>>
    private let sessionTopicToProposal: CodableStore<Session.Proposal>
    private let pairingRegisterer: PairingRegisterer
    private let metadata: AppMetadata
    private let kms: KeyManagementServiceProtocol
    private let logger: ConsoleLogging

    private var publishers = Set<AnyCancellable>()

    init(
        networkingInteractor: NetworkInteracting,
        proposalPayloadsStore: CodableStore<RequestSubscriptionPayload<SessionType.ProposeParams>>,
        sessionTopicToProposal: CodableStore<Session.Proposal>,
        pairingRegisterer: PairingRegisterer,
        metadata: AppMetadata,
        kms: KeyManagementServiceProtocol,
        logger: ConsoleLogging,
        pairingStore: WCPairingStorage,
        sessionStore: WCSessionStorage
    ) {
        self.networkingInteractor = networkingInteractor
        self.proposalPayloadsStore = proposalPayloadsStore
        self.sessionTopicToProposal = sessionTopicToProposal
        self.pairingRegisterer = pairingRegisterer
        self.metadata = metadata
        self.kms = kms
        self.logger = logger
        self.pairingStore = pairingStore
        self.sessionStore = sessionStore

        setupRequestSubscriptions()
        setupResponseSubscriptions()
        setupResponseErrorSubscriptions()
    }

    func approveProposal(proposerPubKey: String, validating sessionNamespaces: [String: SessionNamespace]) async throws {

        guard let payload = try proposalPayloadsStore.get(key: proposerPubKey) else {
            throw Errors.wrongRequestParams
        }

        let proposal = payload.request
        let pairingTopic = payload.topic

        proposalPayloadsStore.delete(forKey: proposerPubKey)

        try Namespace.validate(sessionNamespaces)
        try Namespace.validateApproved(sessionNamespaces, against: proposal.requiredNamespaces)

        let selfPublicKey = try kms.createX25519KeyPair()

        guard let agreementKey = try? kms.performKeyAgreement(
            selfPublicKey: selfPublicKey,
            peerPublicKey: proposal.proposer.publicKey
        ) else { throw Errors.agreementMissingOrInvalid }

        let sessionTopic = agreementKey.derivedTopic()
        try kms.setAgreementSecret(agreementKey, topic: sessionTopic)

        guard let relay = proposal.relays.first else {
            throw Errors.relayNotFound
        }

        let result = SessionType.ProposeResponse(relay: relay, responderPublicKey: selfPublicKey.hexRepresentation)
        let response = RPCResponse(id: payload.id, result: result)

        async let proposeResponse: () = networkingInteractor.respond(topic: payload.topic, response: response, protocolMethod: SessionProposeProtocolMethod())

        async let settleRequest: () = settle(topic: sessionTopic, proposal: proposal, namespaces: sessionNamespaces, pairingTopic: pairingTopic)

        _ = try await [proposeResponse, settleRequest]

        pairingRegisterer.activate(
            pairingTopic: payload.topic,
            peerMetadata: payload.request.proposer.metadata
        )
    }

    func reject(proposerPubKey: String, reason: SignReasonCode) async throws {
        guard let payload = try proposalPayloadsStore.get(key: proposerPubKey) else {
            throw Errors.proposalPayloadsNotFound
        }
        proposalPayloadsStore.delete(forKey: proposerPubKey)
        try await networkingInteractor.respondError(topic: payload.topic, requestId: payload.id, protocolMethod: SessionProposeProtocolMethod(), reason: reason)
        // TODO: Delete pairing if inactive 
    }

    func settle(topic: String, proposal: SessionProposal, namespaces: [String: SessionNamespace], pairingTopic: String) async throws {
        guard let agreementKeys = kms.getAgreementSecret(for: topic) else {
            throw Errors.agreementMissingOrInvalid
        }
        let selfParticipant = Participant(
            publicKey: agreementKeys.publicKey.hexRepresentation,
            metadata: metadata
        )
        guard let relay = proposal.relays.first else {
            throw Errors.relayNotFound
        }

        // TODO: Test expiration times
        let expiry = Date()
            .addingTimeInterval(TimeInterval(WCSession.defaultTimeToLive))
            .timeIntervalSince1970

        let settleParams = SessionType.SettleParams(
            relay: relay,
            controller: selfParticipant,
            namespaces: namespaces,
            expiry: Int64(expiry))

        let session = WCSession(
            topic: topic,
            pairingTopic: pairingTopic,
            timestamp: Date(),
            selfParticipant: selfParticipant,
            peerParticipant: proposal.proposer,
            settleParams: settleParams,
            requiredNamespaces: proposal.requiredNamespaces,
            acknowledged: false)

        logger.debug("Sending session settle request")

        sessionStore.setSession(session)

        let protocolMethod = SessionSettleProtocolMethod()
        let request = RPCRequest(method: protocolMethod.method, params: settleParams)

        async let subscription: () = networkingInteractor.subscribe(topic: topic)
        async let settleRequest: () = networkingInteractor.request(request, topic: topic, protocolMethod: protocolMethod)

        _ = try await [settleRequest, subscription]
        onSessionSettle?(session.publicRepresentation())
    }
}

// MARK: - Privates

private extension ApproveEngine {

    func setupRequestSubscriptions() {
        pairingRegisterer.register(method: SessionProposeProtocolMethod())
            .sink { [unowned self] (payload: RequestSubscriptionPayload<SessionType.ProposeParams>) in
                handleSessionProposeRequest(payload: payload)
            }.store(in: &publishers)

        networkingInteractor.requestSubscription(on: SessionSettleProtocolMethod())
            .sink { [unowned self] (payload: RequestSubscriptionPayload<SessionType.SettleParams>) in
                handleSessionSettleRequest(payload: payload)
            }.store(in: &publishers)
    }

    func setupResponseSubscriptions() {
        networkingInteractor.responseSubscription(on: SessionProposeProtocolMethod())
            .sink { [unowned self] (payload: ResponseSubscriptionPayload<SessionType.ProposeParams, SessionType.ProposeResponse>) in
                handleSessionProposeResponse(payload: payload)
            }.store(in: &publishers)

        networkingInteractor.responseSubscription(on: SessionSettleProtocolMethod())
            .sink { [unowned self] (payload: ResponseSubscriptionPayload<SessionType.SettleParams, Bool>) in
                handleSessionSettleResponse(payload: payload)
            }.store(in: &publishers)
    }

    func setupResponseErrorSubscriptions() {
        networkingInteractor.responseErrorSubscription(on: SessionProposeProtocolMethod())
            .sink { [unowned self] (payload: ResponseSubscriptionErrorPayload<SessionType.ProposeParams>) in
                handleSessionProposeResponseError(payload: payload)
            }.store(in: &publishers)

        networkingInteractor.responseErrorSubscription(on: SessionSettleProtocolMethod())
            .sink { [unowned self] (payload: ResponseSubscriptionErrorPayload<SessionType.SettleParams>) in
                handleSessionSettleResponseError(payload: payload)
            }.store(in: &publishers)
    }

    func respondError(payload: SubscriptionPayload, reason: SignReasonCode, protocolMethod: ProtocolMethod) {
        Task(priority: .high) {
            do {
                try await networkingInteractor.respondError(topic: payload.topic, requestId: payload.id, protocolMethod: protocolMethod, reason: reason)
            } catch {
                logger.error("Respond Error failed with: \(error.localizedDescription)")
            }
        }
    }

    // MARK: SessionProposeResponse
    // TODO: Move to Non-Controller SettleEngine
    func handleSessionProposeResponse(payload: ResponseSubscriptionPayload<SessionType.ProposeParams, SessionType.ProposeResponse>) {
        do {
            let selfPublicKey = try AgreementPublicKey(hex: payload.request.proposer.publicKey)
            let agreementKeys = try kms.performKeyAgreement(selfPublicKey: selfPublicKey, peerPublicKey: payload.response.responderPublicKey)

            let sessionTopic = agreementKeys.derivedTopic()
            logger.debug("Received Session Proposal response")

            try kms.setAgreementSecret(agreementKeys, topic: sessionTopic)

            let proposal = payload.request.publicRepresentation(pairingTopic: payload.topic)
            sessionTopicToProposal.set(proposal, forKey: sessionTopic)
            Task(priority: .high) {
                try await networkingInteractor.subscribe(topic: sessionTopic)
            }
        } catch {
            return logger.debug(error.localizedDescription)
        }
    }

    func handleSessionProposeResponseError(payload: ResponseSubscriptionErrorPayload<SessionType.ProposeParams>) {
        guard let pairing = pairingStore.getPairing(forTopic: payload.topic) else {
            return logger.debug(Errors.pairingNotFound.localizedDescription)
        }

        if !pairing.active {
            kms.deleteSymmetricKey(for: pairing.topic)
            networkingInteractor.unsubscribe(topic: pairing.topic)
            pairingStore.delete(topic: payload.topic)
        }
        logger.debug("Session Proposal has been rejected")
        kms.deletePrivateKey(for: payload.request.proposer.publicKey)

        onSessionRejected?(
            payload.request.publicRepresentation(pairingTopic: payload.topic),
            SessionType.Reason(code: payload.error.code, message: payload.error.message)
        )
    }

    // MARK: SessionSettleResponse

    func handleSessionSettleResponse(payload: ResponseSubscriptionPayload<SessionType.SettleParams, Bool>) {
        guard var session = sessionStore.getSession(forTopic: payload.topic) else {
            return logger.debug(Errors.sessionNotFound.localizedDescription)
        }

        logger.debug("Received session settle response")
        session.acknowledge()
        sessionStore.setSession(session)
    }

    func handleSessionSettleResponseError(payload: ResponseSubscriptionErrorPayload<SessionType.SettleParams>) {
        guard let session = sessionStore.getSession(forTopic: payload.topic) else {
            return logger.debug(Errors.sessionNotFound.localizedDescription)
        }

        logger.error("Error - session rejected, Reason: \(payload.error)")
        networkingInteractor.unsubscribe(topic: payload.topic)
        sessionStore.delete(topic: payload.topic)
        kms.deleteAgreementSecret(for: payload.topic)
        kms.deletePrivateKey(for: session.publicKey!)
    }

    // MARK: SessionProposeRequest

    func handleSessionProposeRequest(payload: RequestSubscriptionPayload<SessionType.ProposeParams>) {
        logger.debug("Received Session Proposal")
        let proposal = payload.request
        do { try Namespace.validate(proposal.requiredNamespaces) } catch {
            return respondError(payload: payload, reason: .invalidUpdateRequest, protocolMethod: SessionProposeProtocolMethod())
        }
        proposalPayloadsStore.set(payload, forKey: proposal.proposer.publicKey)
        onSessionProposal?(proposal.publicRepresentation(pairingTopic: payload.topic))
    }

    // MARK: SessionSettleRequest

    func handleSessionSettleRequest(payload: RequestSubscriptionPayload<SessionType.SettleParams>) {
        logger.debug("Did receive session settle request")

        let protocolMethod = SessionSettleProtocolMethod()

        let sessionTopic = payload.topic

        guard let proposal = try? sessionTopicToProposal.get(key: sessionTopic) else {
            return respondError(payload: payload, reason: .sessionSettlementFailed, protocolMethod: protocolMethod)
        }
        let pairingTopic = proposal.pairingTopic
        let proposedNamespaces = proposal.requiredNamespaces

        let params = payload.request
        let sessionNamespaces = params.namespaces

        do {
            try Namespace.validate(sessionNamespaces)
            try Namespace.validateApproved(sessionNamespaces, against: proposedNamespaces)
        } catch WalletConnectError.unsupportedNamespace(let reason) {
            return respondError(payload: payload, reason: reason, protocolMethod: protocolMethod)
        } catch {
            return respondError(payload: payload, reason: .invalidUpdateRequest, protocolMethod: protocolMethod)
        }

        let agreementKeys = kms.getAgreementSecret(for: sessionTopic)!
        let selfParticipant = Participant(
            publicKey: agreementKeys.publicKey.hexRepresentation,
            metadata: metadata
        )

        pairingRegisterer.activate(
            pairingTopic: pairingTopic,
            peerMetadata: params.controller.metadata
        )

        let session = WCSession(
            topic: sessionTopic,
            pairingTopic: pairingTopic,
            timestamp: Date(),
            selfParticipant: selfParticipant,
            peerParticipant: params.controller,
            settleParams: params,
            requiredNamespaces: proposedNamespaces,
            acknowledged: true
        )
        sessionStore.setSession(session)

        Task(priority: .high) {
            try await networkingInteractor.respondSuccess(topic: payload.topic, requestId: payload.id, protocolMethod: protocolMethod)
        }
        onSessionSettle?(session.publicRepresentation())
    }
}
