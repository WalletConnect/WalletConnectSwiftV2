import Foundation
import Combine
import WalletConnectUtils
import WalletConnectKMS


final class PairingEngine {
    var onPairingExtend: ((Pairing)->())?
    var onSessionProposal: ((Session.Proposal)->())?
    var onProposeResponse: ((String)->())?
    var onSessionRejected: ((Session.Proposal, SessionType.Reason)->())?

    private let proposalPayloadsStore: KeyValueStore<WCRequestSubscriptionPayload>
    private let wcSubscriber: WCSubscribing
    private let relayer: WalletConnectRelaying
    private let kms: KeyManagementServiceProtocol
    private let sequencesStore: PairingSequenceStorage
    private var metadata: AppMetadata
    private var publishers = [AnyCancellable]()
    private let logger: ConsoleLogging
    private let topicInitializer: () -> String
    
    init(relay: WalletConnectRelaying,
         kms: KeyManagementServiceProtocol,
         subscriber: WCSubscribing,
         sequencesStore: PairingSequenceStorage,
         metadata: AppMetadata,
         logger: ConsoleLogging,
         topicGenerator: @escaping () -> String = String.generateTopic,
         proposalPayloadsStore: KeyValueStore<WCRequestSubscriptionPayload> = KeyValueStore<WCRequestSubscriptionPayload>(defaults: RuntimeKeyValueStorage(), identifier: StorageDomainIdentifiers.proposals.rawValue)) {
        self.relayer = relay
        self.kms = kms
        self.wcSubscriber = subscriber
        self.metadata = metadata
        self.sequencesStore = sequencesStore
        self.logger = logger
        self.topicInitializer = topicGenerator
        self.proposalPayloadsStore = proposalPayloadsStore
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
            .map {Pairing(topic: $0.topic, peer: $0.participants.peer, expiryDate: $0.expiryDate)}
    }
    
    func create() -> WalletConnectURI? {
        let topic = topicInitializer()
        let symKey = try! kms.createSymmetricKey(topic)
        let pairing = PairingSequence(topic: topic, selfMetadata: metadata)
        let uri = WalletConnectURI(topic: topic, symKey: symKey.hexRepresentation, relay: pairing.relay)
        sequencesStore.setSequence(pairing)
        wcSubscriber.setSubscription(topic: topic)
        return uri
    }
    
    func propose(pairingTopic: String, blockchains: Set<Blockchain>, methods: Set<String>, events: Set<String>, relay: RelayProtocolOptions, completion: @escaping ((Error?) -> ())) {
        logger.debug("Propose Session on topic: \(pairingTopic)")
        let publicKey = try! kms.createX25519KeyPair()
        let proposer = Participant(
            publicKey: publicKey.hexRepresentation,
            metadata: metadata)
        let proposal = SessionProposal(
            relays: [relay],
            proposer: proposer,
            methods: methods,
            events: events,
            blockchains: blockchains)
        relayer.requestNetworkAck(.wcSessionPropose(proposal), onTopic: pairingTopic) { [unowned self] error in
            logger.debug("Received propose acknowledgement")
            completion(error)
        }
    }
    
    func pair(_ uri: WalletConnectURI) throws {
        guard !hasPairing(for: uri.topic) else {
            throw WalletConnectError.pairingAlreadyExist
        }
        let pairing = PairingSequence(uri: uri)
        let symKey = try! SymmetricKey(hex: uri.symKey) // FIXME: Malformed QR code from external source can crash the SDK
        try! kms.setSymmetricKey(symKey, for: pairing.topic)
//        pairing.activate()
//        try? pairing.extend()
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
    
    func reject(proposal: SessionProposal, reason: ReasonCode) {
        guard let payload = try? proposalPayloadsStore.get(key: proposal.proposer.publicKey) else {
            return
        }
        proposalPayloadsStore.delete(forKey: proposal.proposer.publicKey)
        relayer.respondError(for: payload, reason: reason)
//        todo - delete pairing if inactive
    }
    
    func respondSessionPropose(proposal: SessionType.ProposeParams) -> String? {
        guard let payload = try? proposalPayloadsStore.get(key: proposal.proposer.publicKey) else {
            return nil
        }
        proposalPayloadsStore.delete(forKey: proposal.proposer.publicKey)

        let selfPublicKey = try! kms.createX25519KeyPair()
        var agreementKey: AgreementKeys!
        
        do {
            agreementKey = try kms.performKeyAgreement(selfPublicKey: selfPublicKey, peerPublicKey: proposal.proposer.publicKey)
        } catch {
            relayer.respondError(for: payload, reason: .missingOrInvalid("agreement keys"))
            return nil
        }
        //todo - extend pairing
        let sessionTopic = agreementKey.derivedTopic()

        try! kms.setAgreementSecret(agreementKey, topic: sessionTopic)
        guard let relay = proposal.relays.first else {return nil}
        let proposeResponse = SessionType.ProposeResponse(relay: relay, responder: Participant(publicKey: selfPublicKey.hexRepresentation, metadata: metadata))
        let response = JSONRPCResponse<AnyCodable>(id: payload.wcRequest.id, result: AnyCodable(proposeResponse))
        relayer.respond(topic: payload.topic, response: .response(response)) { _ in }
        return sessionTopic
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
    
    private func wcSessionPropose(_ payload: WCRequestSubscriptionPayload, proposal: SessionType.ProposeParams) {
        logger.debug(proposal)
        try? proposalPayloadsStore.set(payload, forKey: proposal.proposer.publicKey)
        updatePairingMetadata(topic: payload.topic, metadata: proposal.proposer.metadata)
        onSessionProposal?(proposal.publicRepresentation())
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
            self?.wcSubscriber.removeSubscription(topic: pairing.topic)
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
        guard var pairing = sequencesStore.getSequence(forTopic: pairingTopic) else {
            return
        }
        switch result {
        case .response(let response):
            
            // Activate the pairing
            if !pairing.isActive {
                pairing.activate()
            }
            try? pairing.extend()
            sequencesStore.setSequence(pairing)
            
            let selfPublicKey = try! AgreementPublicKey(hex: proposal.proposer.publicKey)
            var agreementKeys: AgreementKeys!
            
            do {
                let proposeResponse = try response.result.get(SessionType.ProposeResponse.self)
                agreementKeys = try kms.performKeyAgreement(selfPublicKey: selfPublicKey, peerPublicKey: proposeResponse.responder.publicKey)
                updatePairingMetadata(topic: pairingTopic, metadata: proposeResponse.responder.metadata)
            } catch {
                //TODO - handle error
                logger.debug(error)
                return
            }

            let sessionTopic = agreementKeys.derivedTopic()
            logger.debug("session topic: \(sessionTopic)")
            try! kms.setAgreementSecret(agreementKeys, topic: sessionTopic)
            onProposeResponse?(sessionTopic)
            
        case .error(let error):
            if !pairing.isActive {
                kms.deleteSymmetricKey(for: pairing.topic)
                wcSubscriber.removeSubscription(topic: pairing.topic)
                sequencesStore.delete(topic: pairingTopic)
            }
            logger.debug("session propose has been rejected")
            kms.deletePrivateKey(for: proposal.proposer.publicKey)
            onSessionRejected?(proposal.publicRepresentation(), SessionType.Reason(code: error.error.code, message: error.error.message))
            return
        }
    }
    
    private func updatePairingMetadata(topic: String, metadata: AppMetadata) {
        guard var pairing = sequencesStore.getSequence(forTopic: topic) else {return}
        pairing.participants.peer = metadata
        sequencesStore.setSequence(pairing)
    }
}
