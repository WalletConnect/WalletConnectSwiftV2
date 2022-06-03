import Foundation
import Combine
import WalletConnectUtils
import WalletConnectKMS

final class ApproveEngine {
    
    enum Response {
        case proposeResponse(topic: String, proposal: SessionProposal)
        case sessionProposal(Session.Proposal)
        case sessionRejected(proposal: Session.Proposal, reason: SessionType.Reason)
    }

    private let networkingInteractor: NetworkInteracting
    private let pairingStore: WCPairingStorage
    private let proposalPayloadsStore: CodableStore<WCRequestSubscriptionPayload>
    private let sessionToPairingTopic: CodableStore<String>
    private let kms: KeyManagementServiceProtocol
    private let logger: ConsoleLogging
    
    private var publishers = Set<AnyCancellable>()
    
    private let approvePublisherSubject = PassthroughSubject<Response, Never>()

    var approvePublisher: AnyPublisher<Response, Never> {
        approvePublisherSubject.eraseToAnyPublisher()
    }

    init(
        networkingInteractor: NetworkInteracting,
        proposalPayloadsStore: CodableStore<WCRequestSubscriptionPayload>,
        sessionToPairingTopic: CodableStore<String>,
        kms: KeyManagementServiceProtocol,
        logger: ConsoleLogging,
        pairingStore: WCPairingStorage
    ) {
        self.networkingInteractor = networkingInteractor
        self.proposalPayloadsStore = proposalPayloadsStore
        self.sessionToPairingTopic = sessionToPairingTopic
        self.kms = kms
        self.logger = logger
        self.pairingStore = pairingStore
        
        setupNetworkingSubscriptions()
    }
    
    func approveProposal(proposerPubKey: String, validating sessionNamespaces: [String: SessionNamespace]) throws -> (String, SessionProposal) {
        
        let payload = try proposalPayloadsStore.get(key: proposerPubKey)
        
        guard let payload = payload, case .sessionPropose(let proposal) = payload.wcRequest.params
        else { throw ApproveEngineError.wrongRequestParams }

        proposalPayloadsStore.delete(forKey: proposerPubKey)
        
        try Namespace.validate(sessionNamespaces)
        try Namespace.validateApproved(sessionNamespaces, against: proposal.requiredNamespaces)
        
        let selfPublicKey = try kms.createX25519KeyPair()
        let agreementKey = try? kms.performKeyAgreement(selfPublicKey: selfPublicKey, peerPublicKey: proposal.proposer.publicKey)
        guard let agreementKey = agreementKey else {
            networkingInteractor.respondError(for: payload, reason: .missingOrInvalid("agreement keys"))
            throw ApproveEngineError.agreementMissingOrInvalid
        }
        // TODO: Extend pairing
        let sessionTopic = agreementKey.derivedTopic()
        try kms.setAgreementSecret(agreementKey, topic: sessionTopic)

        guard let relay = proposal.relays.first else { throw ApproveEngineError.relayNotFound }
        let proposeResponse = SessionType.ProposeResponse(relay: relay, responderPublicKey: selfPublicKey.hexRepresentation)
        let response = JSONRPCResponse<AnyCodable>(id: payload.wcRequest.id, result: AnyCodable(proposeResponse))
        networkingInteractor.respond(topic: payload.topic, response: .response(response)) { _ in }

        return (sessionTopic, proposal)
    }
    
    func reject(proposal: SessionProposal, reason: ReasonCode) throws {
        guard let payload = try proposalPayloadsStore.get(key: proposal.proposer.publicKey)
        else { throw ApproveEngineError.proposalPayloadsNotFound }

        proposalPayloadsStore.delete(forKey: proposal.proposer.publicKey)
        networkingInteractor.respondError(for: payload, reason: reason)
        // TODO: Delete pairing if inactive
    }
}

// MARK: - Privates

private extension ApproveEngine {
    
    func setupNetworkingSubscriptions() {
        networkingInteractor.responsePublisher
            .sink { [unowned self] response in
                self.handleResponse(response)
            }.store(in: &publishers)
        
        networkingInteractor.wcRequestPublisher
            .sink { [unowned self] subscriptionPayload in
                switch subscriptionPayload.wcRequest.params {
                case .sessionPropose(let proposeParams):
                    wcSessionPropose(subscriptionPayload, proposal: proposeParams)
                default:
                    return
                }
            }.store(in: &publishers)
    }
    
    func wcSessionPropose(_ payload: WCRequestSubscriptionPayload, proposal: SessionType.ProposeParams) {
        logger.debug("Received Session Proposal")
        do {
            try Namespace.validate(proposal.requiredNamespaces)
        } catch {
            // TODO: respond error
            return
        }
        proposalPayloadsStore.set(payload, forKey: proposal.proposer.publicKey)
        approvePublisherSubject.send(.sessionProposal(proposal.publicRepresentation()))
    }
    
    func handleResponse(_ response: WCResponse) {
        switch response.requestParams {
        case .sessionPropose(let proposal):
            handleProposeResponse(pairingTopic: response.topic, proposal: proposal, result: response.result)
        default:
            break
        }
    }
    
    func handleProposeResponse(pairingTopic: String, proposal: SessionProposal, result: JsonRpcResult) {
        guard var pairing = pairingStore.getPairing(forTopic: pairingTopic) else {
            return
        }
        switch result {
        case .response(let response):
            
            // Activate the pairing
            if !pairing.active {
                pairing.activate()
            } else {
                try? pairing.updateExpiry()
            }
            
            pairingStore.setPairing(pairing)
            
            let selfPublicKey = try! AgreementPublicKey(hex: proposal.proposer.publicKey)
            var agreementKeys: AgreementKeys!
            
            do {
                let proposeResponse = try response.result.get(SessionType.ProposeResponse.self)
                agreementKeys = try kms.performKeyAgreement(selfPublicKey: selfPublicKey, peerPublicKey: proposeResponse.responderPublicKey)
            } catch {
                //TODO - handle error
                logger.debug(error)
                return
            }

            let sessionTopic = agreementKeys.derivedTopic()
            logger.debug("Received Session Proposal response")
            
            try? kms.setAgreementSecret(agreementKeys, topic: sessionTopic)
            sessionToPairingTopic.set(pairingTopic, forKey: sessionTopic)
            approvePublisherSubject.send(.proposeResponse(topic: sessionTopic, proposal: proposal))
            
        case .error(let error):
            if !pairing.active {
                kms.deleteSymmetricKey(for: pairing.topic)
                networkingInteractor.unsubscribe(topic: pairing.topic)
                pairingStore.delete(topic: pairingTopic)
            }
            logger.debug("Session Proposal has been rejected")
            kms.deletePrivateKey(for: proposal.proposer.publicKey)

            approvePublisherSubject.send(.sessionRejected(
                proposal: proposal.publicRepresentation(),
                reason: SessionType.Reason(code: error.error.code, message: error.error.message)
            ))
        }
    }
}

enum ApproveEngineError: Error {
    case wrongRequestParams
    case relayNotFound
    case proposalPayloadsNotFound
    case agreementMissingOrInvalid
}
