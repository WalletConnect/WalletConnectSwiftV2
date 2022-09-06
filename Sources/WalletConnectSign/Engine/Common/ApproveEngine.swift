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
        case agreementMissingOrInvalid
    }

    var onSessionProposal: ((Session.Proposal) -> Void)?
    var onSessionRejected: ((Session.Proposal, SessionType.Reason) -> Void)?
    var onSessionSettle: ((Session) -> Void)?

    var settlingProposal: SessionProposal?

    private let networkingInteractor: NetworkInteracting
    private let pairingStore: WCPairingStorage
    private let sessionStore: WCSessionStorage
    private let proposalPayloadsStore: CodableStore<RequestSubscriptionPayload<WCRequest>>
    private let sessionToPairingTopic: CodableStore<String>
    private let metadata: AppMetadata
    private let kms: KeyManagementServiceProtocol
    private let logger: ConsoleLogging

    private var publishers = Set<AnyCancellable>()

    init(
        networkingInteractor: NetworkInteracting,
        proposalPayloadsStore: CodableStore<RequestSubscriptionPayload<WCRequest>>,
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

        guard let payload = payload, case .sessionPropose(let proposal) = payload.request else {
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
        try await networkingInteractor.respond(topic: payload.topic, response: response, tag: WCRequest.Method.sessionPropose.responseTag)

        try pairing.updateExpiry()
        pairingStore.setPairing(pairing)

        try await settle(topic: sessionTopic, proposal: proposal, namespaces: sessionNamespaces)
    }

    func reject(proposerPubKey: String, reason: ReasonCode) async throws {
        guard let payload = try proposalPayloadsStore.get(key: proposerPubKey) else {
            throw Errors.proposalPayloadsNotFound
        }
        proposalPayloadsStore.delete(forKey: proposerPubKey)
        try await networkingInteractor.respondError(topic: payload.topic, requestId: payload.id, tag: WCRequest.Method.sessionPropose.responseTag, reason: reason)
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

        let request = RPCRequest(method: WCRequest.Method.sessionSettle.method, params: WCRequest.sessionSettle(settleParams))
        try await networkingInteractor.request(request, topic: topic, tag: WCRequest.Method.sessionSettle.requestTag)
        onSessionSettle?(session.publicRepresentation())
    }
}

// MARK: - Privates

private extension ApproveEngine {

    func setupNetworkingSubscriptions() {
        networkingInteractor.responseSubscription(on: nil)
            .sink { [unowned self] (payload: ResponseSubscriptionPayload<WCRequest, JsonRpcResult>) in
                switch payload.request {
                case .sessionPropose(let proposal):
                    handleSessionProposeResponse(payload: payload, proposal: proposal)
                case .sessionSettle:
                    handleSessionSettleResponse(payload: payload)
                default:
                    break
                }
            }.store(in: &publishers)

        networkingInteractor.requestSubscription(on: nil)
            .sink { [unowned self] (payload: RequestSubscriptionPayload<WCRequest>) in
                switch payload.request {
                case .sessionPropose(let proposal):
                    handleSessionProposeRequest(payload: payload, proposal: proposal)
                case .sessionSettle(let params):
                    handleSessionSettleRequest(payload: payload, params: params)
                default: return
                }
            }.store(in: &publishers)
    }

    func respondError(payload: SubscriptionPayload, reason: ReasonCode, tag: Int) {
        Task {
            do {
                try await networkingInteractor.respondError(topic: payload.topic, requestId: payload.id, tag: tag, reason: reason)
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
    func handleSessionProposeResponse(payload: ResponseSubscriptionPayload<WCRequest, JsonRpcResult>, proposal: SessionType.ProposeParams) {
        do {
            let sessionTopic = try handleProposeResponse(
                pairingTopic: payload.topic,
                proposal: proposal,
                result: payload.response
            )
            settlingProposal = proposal

            Task(priority: .high) {
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

    func handleSessionSettleResponse(payload: ResponseSubscriptionPayload<WCRequest, JsonRpcResult>) {
        guard let session = sessionStore.getSession(forTopic: payload.topic) else { return }
        switch payload.response {
        case .response:
            logger.debug("Received session settle response")
            guard var session = sessionStore.getSession(forTopic: payload.topic) else { return }
            session.acknowledge()
            sessionStore.setSession(session)
        case .error(let error):
            logger.error("Error - session rejected, Reason: \(error)")
            networkingInteractor.unsubscribe(topic: payload.topic)
            sessionStore.delete(topic: payload.topic)
            kms.deleteAgreementSecret(for: payload.topic)
            kms.deletePrivateKey(for: session.publicKey!)
        }
    }

    // MARK: SessionProposeRequest

    func handleSessionProposeRequest(payload: RequestSubscriptionPayload<WCRequest>, proposal: SessionType.ProposeParams) {
        logger.debug("Received Session Proposal")
        do { try Namespace.validate(proposal.requiredNamespaces) } catch {
            return respondError(payload: payload, reason: .invalidUpdateRequest, tag: WCRequest.Method.sessionPropose.responseTag)
        }
        proposalPayloadsStore.set(payload, forKey: proposal.proposer.publicKey)
        onSessionProposal?(proposal.publicRepresentation())
    }

    // MARK: SessionSettleRequest
    func handleSessionSettleRequest(payload: RequestSubscriptionPayload<WCRequest>, params: SessionType.SettleParams) {
        logger.debug("Did receive session settle request")

        let tag = WCRequest.Method.sessionSettle.responseTag

        guard let proposedNamespaces = settlingProposal?.requiredNamespaces else {
            return respondError(payload: payload, reason: .invalidUpdateRequest, tag: tag)
        }

        settlingProposal = nil

        let sessionNamespaces = params.namespaces

        do {
            try Namespace.validate(sessionNamespaces)
            try Namespace.validateApproved(sessionNamespaces, against: proposedNamespaces)
        } catch WalletConnectError.unsupportedNamespace(let reason) {
            return respondError(payload: payload, reason: reason, tag: tag)
        } catch {
            return respondError(payload: payload, reason: .invalidUpdateRequest, tag: tag)
        }

        let topic = payload.topic
        let agreementKeys = kms.getAgreementSecret(for: topic)!
        let selfParticipant = Participant(
            publicKey: agreementKeys.publicKey.hexRepresentation,
            metadata: metadata
        )
        if let pairingTopic = try? sessionToPairingTopic.get(key: topic) {
            updatePairingMetadata(topic: pairingTopic, metadata: params.controller.metadata)
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
            try await networkingInteractor.respondSuccess(topic: payload.topic, requestId: payload.id, tag: tag)
        }
        onSessionSettle?(session.publicRepresentation())
    }
}
