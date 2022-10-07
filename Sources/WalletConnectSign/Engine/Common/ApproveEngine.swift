import Foundation
import Combine
import JSONRPC
import WalletConnectUtils
import WalletConnectKMS
import WalletConnectPairing
import WalletConnectNetworking

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

    var settlingProposal: SessionProposal?

    private let networkingInteractor: NetworkInteracting
    private let pairingStore: WCPairingStorage
    private let sessionStore: WCSessionStorage
    private let proposalPayloadsStore: CodableStore<RequestSubscriptionPayload<SessionType.ProposeParams>>
    private let sessionToPairingTopic: CodableStore<String>
    private let pairingRegisterer: PairingRegisterer
    private let metadata: AppMetadata
    private let kms: KeyManagementServiceProtocol
    private let logger: ConsoleLogging

    private var publishers = Set<AnyCancellable>()

    init(
        networkingInteractor: NetworkInteracting,
        proposalPayloadsStore: CodableStore<RequestSubscriptionPayload<SessionType.ProposeParams>>,
        sessionToPairingTopic: CodableStore<String>,
        pairingRegisterer: PairingRegisterer,
        metadata: AppMetadata,
        kms: KeyManagementServiceProtocol,
        logger: ConsoleLogging,
        pairingStore: WCPairingStorage,
        sessionStore: WCSessionStorage
    ) {
        self.networkingInteractor = networkingInteractor
        self.proposalPayloadsStore = proposalPayloadsStore
        self.sessionToPairingTopic = sessionToPairingTopic
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

        guard var pairing = pairingStore.getPairing(forTopic: payload.topic) else {
            throw Errors.pairingNotFound
        }

        let result = SessionType.ProposeResponse(relay: relay, responderPublicKey: selfPublicKey.hexRepresentation)
        let response = RPCResponse(id: payload.id, result: result)
        try await networkingInteractor.respond(topic: payload.topic, response: response, protocolMethod: SessionProposeProtocolMethod())

        try pairing.updateExpiry()
        pairingStore.setPairing(pairing)

        try await settle(topic: sessionTopic, proposal: proposal, namespaces: sessionNamespaces)
    }

    func reject(proposerPubKey: String, reason: ReasonCode) async throws {
        guard let payload = try proposalPayloadsStore.get(key: proposerPubKey) else {
            throw Errors.proposalPayloadsNotFound
        }
        proposalPayloadsStore.delete(forKey: proposerPubKey)
        try await networkingInteractor.respondError(topic: payload.topic, requestId: payload.id, protocolMethod: SessionProposeProtocolMethod(), reason: reason)
        // TODO: Delete pairing if inactive 
    }

    func settle(topic: String, proposal: SessionProposal, namespaces: [String: SessionNamespace]) async throws {
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
            timestamp: Date(),
            selfParticipant: selfParticipant,
            peerParticipant: proposal.proposer,
            settleParams: settleParams,
            requiredNamespaces: proposal.requiredNamespaces,
            acknowledged: false)

        logger.debug("Sending session settle request")

        try await networkingInteractor.subscribe(topic: topic)
        sessionStore.setSession(session)

        let protocolMethod = SessionSettleProtocolMethod()
        let request = RPCRequest(method: protocolMethod.method, params: settleParams)
        try await networkingInteractor.request(request, topic: topic, protocolMethod: protocolMethod)
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

    func respondError(payload: SubscriptionPayload, reason: ReasonCode, protocolMethod: ProtocolMethod) {
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
            let pairingTopic = payload.topic

            guard var pairing = pairingStore.getPairing(forTopic: pairingTopic) else {
                throw Errors.pairingNotFound
            }

            // Activate the pairing
            if !pairing.active {
                pairing.activate()
            } else {
                try pairing.updateExpiry()
            }

            pairingStore.setPairing(pairing)

            let selfPublicKey = try AgreementPublicKey(hex: payload.request.proposer.publicKey)
            let agreementKeys = try kms.performKeyAgreement(selfPublicKey: selfPublicKey, peerPublicKey: payload.response.responderPublicKey)

            let sessionTopic = agreementKeys.derivedTopic()
            logger.debug("Received Session Proposal response")

            try kms.setAgreementSecret(agreementKeys, topic: sessionTopic)
            sessionToPairingTopic.set(pairingTopic, forKey: sessionTopic)

            settlingProposal = payload.request

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
            payload.request.publicRepresentation(),
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
        onSessionProposal?(proposal.publicRepresentation())
    }

    // MARK: SessionSettleRequest

    func handleSessionSettleRequest(payload: RequestSubscriptionPayload<SessionType.SettleParams>) {
        logger.debug("Did receive session settle request")

        let protocolMethod = SessionSettleProtocolMethod()

        guard let proposedNamespaces = settlingProposal?.requiredNamespaces else {
            return respondError(payload: payload, reason: .invalidUpdateRequest, protocolMethod: protocolMethod)
        }

        settlingProposal = nil

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

        let topic = payload.topic
        let agreementKeys = kms.getAgreementSecret(for: topic)!
        let selfParticipant = Participant(
            publicKey: agreementKeys.publicKey.hexRepresentation,
            metadata: metadata
        )
        if let pairingTopic = try? sessionToPairingTopic.get(key: topic) {
            pairingRegisterer.updateMetadata(pairingTopic, metadata: params.controller.metadata)
        }

        let session = WCSession(
            topic: topic,
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
