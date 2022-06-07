import Foundation
import Combine
import WalletConnectUtils
import WalletConnectKMS

final class ApproveEngine {

    enum Error: String, Swift.Error {
        case wrongRequestParams
        case relayNotFound
        case proposalPayloadsNotFound
        case pairingNotFound
        case agreementMissingOrInvalid
    }
    
    typealias SessionProposalCallback = (Session.Proposal) -> Void
    typealias SessionRejectedCallback = (Session.Proposal, SessionType.Reason) -> Void
    typealias SessionSettleCallback = (Session) -> Void
    
    var onSessionProposal: SessionProposalCallback?
    var onSessionRejected: SessionRejectedCallback?
    var onSessionSettle: SessionSettleCallback?
    
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
    
    func approveProposal(proposerPubKey: String, validating sessionNamespaces: [String: SessionNamespace]) throws -> (String, SessionProposal) {
        let payload = try proposalPayloadsStore.get(key: proposerPubKey)

        guard let payload = payload, case .sessionPropose(let proposal) = payload.wcRequest.params else {
            throw Error.wrongRequestParams
        }

        proposalPayloadsStore.delete(forKey: proposerPubKey)
        
        try Namespace.validate(sessionNamespaces)
        try Namespace.validateApproved(sessionNamespaces, against: proposal.requiredNamespaces)
        
        let selfPublicKey = try kms.createX25519KeyPair()

        guard let agreementKey = try? kms.performKeyAgreement(
            selfPublicKey: selfPublicKey,
            peerPublicKey: proposal.proposer.publicKey
        ) else { throw Error.agreementMissingOrInvalid }

        // TODO: Extend pairing
        let sessionTopic = agreementKey.derivedTopic()
        try kms.setAgreementSecret(agreementKey, topic: sessionTopic)

        guard let relay = proposal.relays.first else {
            throw Error.relayNotFound
        }

        let proposeResponse = SessionType.ProposeResponse(relay: relay, responderPublicKey: selfPublicKey.hexRepresentation)
        let response = JSONRPCResponse<AnyCodable>(id: payload.wcRequest.id, result: AnyCodable(proposeResponse))
        networkingInteractor.respond(topic: payload.topic, response: .response(response)) { _ in }

        return (sessionTopic, proposal)
    }
    
    func reject(proposal: SessionProposal, reason: ReasonCode) throws {
        guard let payload = try proposalPayloadsStore.get(key: proposal.proposer.publicKey) else {
            throw Error.proposalPayloadsNotFound
        }
        proposalPayloadsStore.delete(forKey: proposal.proposer.publicKey)
        networkingInteractor.respondError(for: payload, reason: reason)
        // TODO: Delete pairing if inactive
    }
    
    func settle(topic: String, proposal: SessionProposal, namespaces: [String: SessionNamespace]) throws {
        guard let agreementKeys = try kms.getAgreementSecret(for: topic) else {
            throw Error.agreementMissingOrInvalid
        }
        let selfParticipant = Participant(
            publicKey: agreementKeys.publicKey.hexRepresentation,
            metadata: metadata
        )
        let expectedExpiryTimeStamp = Date().addingTimeInterval(TimeInterval(WCSession.defaultTimeToLive))
        
        guard let relay = proposal.relays.first else {
            throw Error.relayNotFound
        }

        // TODO: Test expiration times
        let settleParams = SessionType.SettleParams(
            relay: relay,
            controller: selfParticipant,
            namespaces: namespaces,
            expiry: Int64(expectedExpiryTimeStamp.timeIntervalSince1970)
        )
        let session = WCSession(
            topic: topic,
            selfParticipant: selfParticipant,
            peerParticipant: proposal.proposer,
            settleParams: settleParams,
            acknowledged: false
        )

        logger.debug("Sending session settle request")

        Task { try? await networkingInteractor.subscribe(topic: topic) }
        sessionStore.setSession(session)
        networkingInteractor.request(.wcSessionSettle(settleParams), onTopic: topic)
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
                switch subscriptionPayload.wcRequest.params {
                case .sessionPropose(let proposal):
                    handleSessionProposeRequest(payload: subscriptionPayload, proposal: proposal)
                case .sessionSettle(let settleParams):
                    handleSessionSettleRequest(payload: subscriptionPayload, settleParams: settleParams)
                default:
                    return
                }
            }.store(in: &publishers)
    }
    
    func updatePairingMetadata(topic: String, metadata: AppMetadata) {
        guard var pairing = pairingStore.getPairing(forTopic: topic) else { return }
        pairing.peerMetadata = metadata
        pairingStore.setPairing(pairing)
    }
    
    // MARK: SessionProposeResponse
    
    func handleSessionProposeResponse(response: WCResponse, proposal: SessionType.ProposeParams) {
        do {
            let sessionTopic = try handleProposeResponse(
                pairingTopic: response.topic,
                proposal: proposal,
                result: response.result
            )
            settlingProposal = proposal

            Task { try? await networkingInteractor.subscribe(topic: sessionTopic) }
        }
        catch {
            guard let error = error as? JSONRPCErrorResponse else {
                return logger.debug(error.localizedDescription)
            }
            onSessionRejected?(proposal.publicRepresentation(), SessionType.Reason(code: error.error.code, message: error.error.message))
        }
    }
    
    func handleProposeResponse(pairingTopic: String, proposal: SessionProposal, result: JsonRpcResult) throws -> String {
        guard var pairing = pairingStore.getPairing(forTopic: pairingTopic)
        else { throw Error.pairingNotFound }

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
    
    func handleSessionProposeRequest(payload: WCRequestSubscriptionPayload, proposal: SessionType.ProposeParams) {
        do {
            logger.debug("Received Session Proposal")
            try Namespace.validate(proposal.requiredNamespaces)
            proposalPayloadsStore.set(payload, forKey: proposal.proposer.publicKey)
            onSessionProposal?(proposal.publicRepresentation())
        }
        catch {
            // TODO: Return reasons with 6000 code Issue: #253
            networkingInteractor.respondError(for: payload, reason: .invalidUpdateNamespaceRequest)
        }
    }
    
    // MARK: SessionSettleRequest
    
    func handleSessionSettleRequest(payload: WCRequestSubscriptionPayload, settleParams: SessionType.SettleParams) {
        logger.debug("Did receive session settle request")
        guard let proposedNamespaces = settlingProposal?.requiredNamespaces else {
            // TODO: respond error
            return
        }
        settlingProposal = nil
        let sessionNamespaces = settleParams.namespaces
        do {
            try Namespace.validate(proposedNamespaces)
            try Namespace.validate(sessionNamespaces)
            try Namespace.validateApproved(sessionNamespaces, against: proposedNamespaces)
        } catch {
            // TODO: respond error
            return
        }
                
        let topic = payload.topic
        
        let agreementKeys = try! kms.getAgreementSecret(for: topic)!
        
        let selfParticipant = Participant(publicKey: agreementKeys.publicKey.hexRepresentation, metadata: metadata)
        
        if let pairingTopic = try? sessionToPairingTopic.get(key: topic) {
            updatePairingMetadata(topic: pairingTopic, metadata: settleParams.controller.metadata)
        }
        
        let session = WCSession(
            topic: topic,
            selfParticipant: selfParticipant,
            peerParticipant: settleParams.controller,
            settleParams: settleParams,
            acknowledged: true)
        sessionStore.setSession(session)
        networkingInteractor.respondSuccess(for: payload)
        onSessionSettle?(session.publicRepresentation())
    }
}
