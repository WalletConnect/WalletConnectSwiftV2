import Foundation
import Combine
import WalletConnectUtils
import WalletConnectKMS

final class PairingEngine {
    var onApprovalAcknowledgement: ((Pairing) -> Void)?
    var onPairingExtend: ((Pairing)->())?
    var onSessionProposal: ((Session.Proposal)->())?
    var onProposeResponse: ((String)->())?
    var onSessionRejected: ((Session.Proposal, SessionType.Reason)->())?

    
    private let wcSubscriber: WCSubscribing
    private let relayer: WalletConnectRelaying
    private let kms: KeyManagementServiceProtocol
    private let sequencesStore: PairingSequenceStorage
    private var metadata: AppMetadata
    private var publishers = [AnyCancellable]()
    private let logger: ConsoleLogging
    private var sessionPermissions: [String: SessionPermissions] = [:]
    private let topicInitializer: () -> String
    
    init(relay: WalletConnectRelaying,
         kms: KeyManagementServiceProtocol,
         subscriber: WCSubscribing,
         sequencesStore: PairingSequenceStorage,
         metadata: AppMetadata,
         logger: ConsoleLogging,
         topicGenerator: @escaping () -> String = String.generateTopic) {
        self.relayer = relay
        self.kms = kms
        self.wcSubscriber = subscriber
        self.metadata = metadata
        self.sequencesStore = sequencesStore
        self.logger = logger
        self.topicInitializer = topicGenerator
        setUpWCRequestHandling()
        setupExpirationHandling()
        restoreSubscriptions()
        relayer.onPairingResponse = { [weak self] in
            self?.handleResponse($0)
        }
    }
    
    func hasPairing(for topic: String) -> Bool {
        return sequencesStore.hasSequence(forTopic: topic)
    }
    
    func getSettledPairing(for topic: String) -> PairingSequence? {
        guard let pairing = sequencesStore.getSequence(forTopic: topic) else {
            return nil
        }
        return pairing
    }
    
    func getSettledPairings() -> [Pairing] {
        sequencesStore.getAll()
            .map { Pairing(topic: $0.topic, peer: $0.state?.metadata, expiryDate: $0.expiryDate) }
    }
    
    func create() -> WalletConnectURI? {
        let topic = topicInitializer()
        let symKey = try! kms.createSymmetricKey(topic)
        let pairing = PairingSequence.build(topic)
        let uri = WalletConnectURI(topic: topic, symKey: symKey.hexRepresentation, relay: pairing.relay)
        sequencesStore.setSequence(pairing)
        wcSubscriber.setSubscription(topic: topic)
        return uri
    }
    // todo - move to proposer to payload
    var proposals = [String: SessionProposal]()
    
    func propose(pairingTopic: String, permissions: SessionPermissions, relay: RelayProtocolOptions) {
        logger.debug("Propose Session on topic: \(pairingTopic)")
        let publicKey = try! kms.createX25519KeyPair()
        let proposer = Participant(
            publicKey: publicKey.hexRepresentation,
            metadata: metadata)
        let proposal = SessionProposal(
            relay: relay,
            proposer: proposer,
            permissions: permissions,
            blockchainProposed: Blockchain(chains: [], accounts: [])) //todo!!
        
//        let pendingSession = SessionSequence.buildProposed(proposal: proposal, topic: pairingTopic)
        
        proposals[pairingTopic] = proposal
//        sequencesStore.setSequence(pendingSession)
        relayer.request(.wcSessionPropose(proposal), onTopic: pairingTopic) { [unowned self] result in
            switch result {
            case .success:
                logger.debug("Session Proposal response received")
            case .failure(let error):
                logger.debug("Could not send session proposal error: \(error)")
            }
        }
    }
    
    func pair(_ uri: WalletConnectURI) throws {
        guard !hasPairing(for: uri.topic) else {
            throw WalletConnectError.pairingAlreadyExist
        }
        let pairing = PairingSequence.createFromURI(uri)
        let symKey = try! SymmetricKey(hex: uri.symKey)
        try! kms.setSymmetricKey(symKey, for: pairing.topic)
        wcSubscriber.setSubscription(topic: pairing.topic)
        sequencesStore.setSequence(pairing)
    }
    
    func ping(topic: String, completion: @escaping ((Result<Void, Error>) -> ())) {
        guard sequencesStore.hasSequence(forTopic: topic) else {
            logger.debug("Could not find pairing to ping for topic \(topic)")
            return
        }
        relayer.request(.wcPairingPing, onTopic: topic) { [unowned self] result in
            switch result {
            case .success(_):
                logger.debug("Did receive ping response")
                completion(.success(()))
            case .failure(let error):
                logger.debug("error: \(error)")
            }
        }
    }

    //MARK: - Private

    private func setUpWCRequestHandling() {
        wcSubscriber.onReceivePayload = { [unowned self] subscriptionPayload in
            switch subscriptionPayload.wcRequest.params {
            case .pairingPing(_):
                wcPairingPing(subscriptionPayload)
            case .sessionPropose(let proposeParams):
                wcSessionPropose(subscriptionPayload, proposal: proposeParams)
            default:
                logger.warn("Warning: Pairing Engine - Unexpected method type: \(subscriptionPayload.wcRequest.method) received from subscriber")
            }
        }
    }
    
    private var proposerToRequestPayload: [String: WCRequestSubscriptionPayload] = [:]

    
    private func wcSessionPropose(_ payload: WCRequestSubscriptionPayload, proposal: SessionType.ProposeParams) {
        proposerToRequestPayload[proposal.proposer.publicKey] = payload
        onSessionProposal?(proposal.publicRepresentation())
    }
    
    func reject(proposal: SessionProposal, reason: ReasonCode) {
        guard let payload = proposerToRequestPayload[proposal.proposer.publicKey] else {
            return
        }
        proposerToRequestPayload[proposal.proposer.publicKey] = nil
        relayer.respondError(for: payload, reason: reason)
    }
    
    func respondSessionPropose(proposal: SessionType.ProposeParams) -> String? {
        guard let payload = proposerToRequestPayload[proposal.proposer.publicKey] else {
            return nil
        }
        proposerToRequestPayload[proposal.proposer.publicKey] = nil
        
        let selfPublicKey = try! kms.createX25519KeyPair()
        var agreementKey: AgreementSecret!
        
        do {
            agreementKey = try kms.performKeyAgreement(selfPublicKey: selfPublicKey, peerPublicKey: proposal.proposer.publicKey)
        } catch {
            relayer.respondError(for: payload, reason: .missingOrInvalid("agreement keys"))
            return nil
        }

        let sessionTopic = agreementKey.derivedTopic()

        try! kms.setAgreementSecret(agreementKey, topic: sessionTopic)
        wcSubscriber.setSubscription(topic: sessionTopic)
        let proposeResponse = SessionType.ProposeResponse(relay: proposal.relay, responder: AgreementPeer(publicKey: selfPublicKey.hexRepresentation))
        let response = JSONRPCResponse<AnyCodable>(id: payload.wcRequest.id, result: AnyCodable(proposeResponse))
        relayer.respond(topic: payload.topic, response: .response(response)) { _ in }
        return sessionTopic
    }
    
    private func wcPairingPing(_ payload: WCRequestSubscriptionPayload) {
        relayer.respondSuccess(for: payload)
    }
    
    private func restoreSubscriptions() {
        relayer.transportConnectionPublisher
            .sink { [unowned self] (_) in
                let topics = sequencesStore.getAll()
                    .map{$0.topic}
                topics.forEach{self.wcSubscriber.setSubscription(topic: $0)}
            }.store(in: &publishers)
    }
    
    private func setupExpirationHandling() {
        sequencesStore.onSequenceExpiration = { [weak self] pairing in
            self?.kms.deleteSymmetricKey(for: pairing.topic)
        }
    }
    
    private func handleResponse(_ response: WCResponse) {
        switch response.requestParams {
        case .sessionPropose(let proposal):
            handleProposeResponse(pairingTopic: response.topic, proposal: proposal, result: response.result)
        default:
            break
        }
    }
    
    private func handleProposeResponse(pairingTopic: String, proposal: SessionProposal, result: JsonRpcResult) {
        switch result {
        case .response(let response):
            let selfPublicKey = try! AgreementPublicKey(hex: proposal.proposer.publicKey)
            var agreementKeys: AgreementSecret!
            
            do {
                let proposeResponse = try response.result.get(SessionType.ProposeResponse.self)
                agreementKeys = try kms.performKeyAgreement(selfPublicKey: selfPublicKey, peerPublicKey: proposeResponse.responder.publicKey)
            } catch {
                //TODO - handle error
                return
            }

            let sessionTopic = agreementKeys.derivedTopic()
            try! kms.setAgreementSecret(agreementKeys, topic: sessionTopic)

            onProposeResponse?(sessionTopic)
            
        case .error(let error):
            kms.deletePrivateKey(for: proposal.proposer.publicKey)
            sequencesStore.delete(topic: pairingTopic)
            onSessionRejected?(proposal.publicRepresentation(), SessionType.Reason(code: error.error.code, message: error.error.message))
            return
        }
    }
    
}
