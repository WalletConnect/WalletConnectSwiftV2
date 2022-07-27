import Foundation
import Combine
import WalletConnectUtils
import WalletConnectKMS

final class ApproveEngine {
    enum Errors: Error {
        case wrongRequestParams
        case relayNotFound
        case proposalPayloadsNotFound
        case pairingNotFound
        case agreementMissingOrInvalid
        case respondError(payload: WCRequestSubscriptionPayload, reason: ReasonCode)
    }

    var onSessionProposal: ((Session.Proposal) -> Void)?
    var onSessionRejected: ((Session.Proposal, SessionType.Reason) -> Void)?
    var onSessionSettle: ((Session) -> Void)?

    var settlingProposal: SessionProposal?

    private let networkingInteractor: NetworkInteracting
    private let pairingStore: WCPairingStorage
    private let sessionStore: WCSessionStorage
    private let proposalPayloadsStore: CodableStore<WCRequestSubscriptionPayload>
    private let sessionToPairingTopic: CodableStore<String>
    private let metadata: AppMetadata
    private let kms: KeyManagementServiceProtocol
    private let logger: ConsoleLogging

    private var publishers = Set<AnyCancellable>()

    init(
        networkingInteractor: NetworkInteracting,
        proposalPayloadsStore: CodableStore<WCRequestSubscriptionPayload>,
        sessionToPairingTopic: CodableStore<String>,
        metadata: AppMetadata,
        kms: KeyManagementServiceProtocol,
        logger: ConsoleLogging,
        pairingStore: WCPairingStorage,
        sessionStore: WCSessionStorage
    ) {
        self.networkingInteractor = networkingInteractor
        self.proposalPayloadsStore = proposalPayloadsStore
        self.sessionToPairingTopic = sessionToPairingTopic
        self.metadata = metadata
        self.kms = kms
        self.logger = logger
        self.pairingStore = pairingStore
        self.sessionStore = sessionStore

        setupNetworkingSubscriptions()
    }

    func approveProposal(proposerPubKey: String, validating sessionNamespaces: [String: SessionNamespace]) async throws {
        let payload = try proposalPayloadsStore.get(key: proposerPubKey)

        guard let payload = payload, case .sessionPropose(let proposal) = payload.wcRequest.params else {
            throw Errors.wrongRequestParams
        }

        proposalPayloadsStore.delete(forKey: proposerPubKey)

        try Namespace.validate(sessionNamespaces)
        try Namespace.validateApproved(sessionNamespaces, against: proposal.requiredNamespaces)

        let selfPublicKey = try kms.createX25519KeyPair()

        guard let agreementKey = try? kms.performKeyAgreement(
            selfPublicKey: selfPublicKey,
            peerPublicKey: proposal.proposer.publicKey
        ) else { throw Errors.agreementMissingOrInvalid }

        // TODO: Extend pairing
        let sessionTopic = agreementKey.derivedTopic()
        try kms.setAgreementSecret(agreementKey, topic: sessionTopic)

        guard let relay = proposal.relays.first else {
            throw Errors.relayNotFound
        }

        let proposeResponse = SessionType.ProposeResponse(relay: relay, responderPublicKey: selfPublicKey.hexRepresentation)
        let response = JSONRPCResponse<AnyCodable>(id: payload.wcRequest.id, result: AnyCodable(proposeResponse))

        guard var pairing = pairingStore.getPairing(forTopic: payload.topic) else {
            throw Errors.pairingNotFound
        }

        try await networkingInteractor.respond(topic: payload.topic, response: .response(response), tag: payload.wcRequest.responseTag)

        try pairing.updateExpiry()
        pairingStore.setPairing(pairing)

        try await settle(topic: sessionTopic, proposal: proposal, namespaces: sessionNamespaces)
    }

    func reject(proposerPubKey: String, reason: ReasonCode) async throws {
        guard let payload = try proposalPayloadsStore.get(key: proposerPubKey) else {
            throw Errors.proposalPayloadsNotFound
        }
        proposalPayloadsStore.delete(forKey: proposerPubKey)
        try await networkingInteractor.respondError(payload: payload, reason: reason)
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

        try await networkingInteractor.request(.wcSessionSettle(settleParams), onTopic: topic)
        onSessionSettle?(session.publicRepresentation())
    }
}

// MARK: - Privates

private extension ApproveEngine {

    func setupNetworkingSubscriptions() {
        networkingInteractor.responsePublisher
            .sink { [unowned self] response in
                switch response.requestParams {
                case .sessionPropose(let proposal):
                    handleSessionProposeResponse(response: response, proposal: proposal)
                case .sessionSettle:
                    handleSessionSettleResponse(response: response)
                default:
                    break
                }
            }.store(in: &publishers)

        networkingInteractor.wcRequestPublisher
            .sink { [unowned self] subscriptionPayload in
                do {
                    switch subscriptionPayload.wcRequest.params {
                    case .sessionPropose(let proposal):
                        try handleSessionProposeRequest(payload: subscriptionPayload, proposal: proposal)
                    case .sessionSettle(let settleParams):
                        try handleSessionSettleRequest(payload: subscriptionPayload, settleParams: settleParams)
                    default: return
                    }
                } catch Errors.respondError(let payload, let reason) {
                    respondError(payload: payload, reason: reason)
                } catch {
                    logger.error("Unexpected Error: \(error.localizedDescription)")
                }
            }.store(in: &publishers)
    }

    func respondError(payload: WCRequestSubscriptionPayload, reason: ReasonCode) {
        Task {
            do {
                try await networkingInteractor.respondError(payload: payload, reason: reason)
            } catch {
                logger.error("Respond Error failed with: \(error.localizedDescription)")
            }
        }
    }

    func updatePairingMetadata(topic: String, metadata: AppMetadata) {
        guard var pairing = pairingStore.getPairing(forTopic: topic) else { return }
        pairing.peerMetadata = metadata
        pairingStore.setPairing(pairing)
    }

    // MARK: SessionProposeResponse
    // TODO: Move to Non-Controller SettleEngine
    func handleSessionProposeResponse(response: WCResponse, proposal: SessionType.ProposeParams) {
        do {
            let sessionTopic = try handleProposeResponse(
                pairingTopic: response.topic,
                proposal: proposal,
                result: response.result
            )
            settlingProposal = proposal

            Task(priority: .background) {
                try? await networkingInteractor.subscribe(topic: sessionTopic)
            }
        } catch {
            guard let error = error as? JSONRPCErrorResponse else {
                return logger.debug(error.localizedDescription)
            }
            onSessionRejected?(proposal.publicRepresentation(), SessionType.Reason(code: error.error.code, message: error.error.message))
        }
    }

    func handleProposeResponse(pairingTopic: String, proposal: SessionProposal, result: JsonRpcResult) throws -> String {
        guard var pairing = pairingStore.getPairing(forTopic: pairingTopic)
        else { throw Errors.pairingNotFound }

        switch result {
        case .response(let response):
            // Activate the pairing
            if !pairing.active {
                pairing.activate()
            } else {
                try pairing.updateExpiry()
            }

            pairingStore.setPairing(pairing)

            let selfPublicKey = try AgreementPublicKey(hex: proposal.proposer.publicKey)
            let proposeResponse = try response.result.get(SessionType.ProposeResponse.self)
            let agreementKeys = try kms.performKeyAgreement(selfPublicKey: selfPublicKey, peerPublicKey: proposeResponse.responderPublicKey)

            let sessionTopic = agreementKeys.derivedTopic()
            logger.debug("Received Session Proposal response")

            try kms.setAgreementSecret(agreementKeys, topic: sessionTopic)
            sessionToPairingTopic.set(pairingTopic, forKey: sessionTopic)

            return sessionTopic

        case .error(let error):
            if !pairing.active {
                kms.deleteSymmetricKey(for: pairing.topic)
                networkingInteractor.unsubscribe(topic: pairing.topic)
                pairingStore.delete(topic: pairingTopic)
            }
            logger.debug("Session Proposal has been rejected")
            kms.deletePrivateKey(for: proposal.proposer.publicKey)
            throw error
        }
    }

    // MARK: SessionSettleResponse

    func handleSessionSettleResponse(response: WCResponse) {
        guard let session = sessionStore.getSession(forTopic: response.topic) else { return }
        switch response.result {
        case .response:
            logger.debug("Received session settle response")
            guard var session = sessionStore.getSession(forTopic: response.topic) else { return }
            session.acknowledge()
            sessionStore.setSession(session)
        case .error(let error):
            logger.error("Error - session rejected, Reason: \(error)")
            networkingInteractor.unsubscribe(topic: response.topic)
            sessionStore.delete(topic: response.topic)
            kms.deleteAgreementSecret(for: response.topic)
            kms.deletePrivateKey(for: session.publicKey!)
        }
    }

    // MARK: SessionProposeRequest

    func handleSessionProposeRequest(payload: WCRequestSubscriptionPayload, proposal: SessionType.ProposeParams) throws {
        logger.debug("Received Session Proposal")
        do { try Namespace.validate(proposal.requiredNamespaces) } catch { throw Errors.respondError(payload: payload, reason: .invalidUpdateNamespaceRequest) }
        proposalPayloadsStore.set(payload, forKey: proposal.proposer.publicKey)
        onSessionProposal?(proposal.publicRepresentation())
    }

    // MARK: SessionSettleRequest
    func handleSessionSettleRequest(payload: WCRequestSubscriptionPayload, settleParams: SessionType.SettleParams) throws {
        logger.debug("Did receive session settle request")

        guard let proposedNamespaces = settlingProposal?.requiredNamespaces
        else { throw Errors.respondError(payload: payload, reason: .invalidUpdateNamespaceRequest) }

        settlingProposal = nil

        let sessionNamespaces = settleParams.namespaces

        do {
            try Namespace.validate(sessionNamespaces)
            try Namespace.validateApproved(sessionNamespaces, against: proposedNamespaces)
        } catch WalletConnectError.unsupportedNamespace(let reason) {
            throw Errors.respondError(payload: payload, reason: reason)
        }

        let topic = payload.topic
        let agreementKeys = kms.getAgreementSecret(for: topic)!
        let selfParticipant = Participant(
            publicKey: agreementKeys.publicKey.hexRepresentation,
            metadata: metadata
        )
        if let pairingTopic = try? sessionToPairingTopic.get(key: topic) {
            updatePairingMetadata(topic: pairingTopic, metadata: settleParams.controller.metadata)
        }

        let session = WCSession(
            topic: topic,
            timestamp: Date(),
            selfParticipant: selfParticipant,
            peerParticipant: settleParams.controller,
            settleParams: settleParams,
            requiredNamespaces: proposedNamespaces,
            acknowledged: true
        )
        sessionStore.setSession(session)
        networkingInteractor.respondSuccess(for: payload)
        onSessionSettle?(session.publicRepresentation())
    }
}
