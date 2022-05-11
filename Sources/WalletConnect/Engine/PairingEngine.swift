import Foundation
import Combine
import WalletConnectUtils
import WalletConnectKMS


final class PairingEngine {
    var onSessionProposal: ((Session.Proposal)->())?
    var onProposeResponse: ((String)->())?
    var onSessionRejected: ((Session.Proposal, SessionType.Reason)->())?

    private let proposalPayloadsStore: KeyValueStore<WCRequestSubscriptionPayload>
    private let networkingInteractor: NetworkInteracting
    private let kms: KeyManagementServiceProtocol
    private let pairingStore: WCPairingStorage
    private let sessionToPairingTopic: KeyValueStore<String>
    private var metadata: AppMetadata
    private var publishers = [AnyCancellable]()
    private let logger: ConsoleLogging
    private let topicInitializer: () -> String
    
    init(networkingInteractor: NetworkInteracting,
         kms: KeyManagementServiceProtocol,
         pairingStore: WCPairingStorage,
         sessionToPairingTopic: KeyValueStore<String>,
         metadata: AppMetadata,
         logger: ConsoleLogging,
         topicGenerator: @escaping () -> String = String.generateTopic,
         proposalPayloadsStore: KeyValueStore<WCRequestSubscriptionPayload> = KeyValueStore<WCRequestSubscriptionPayload>(defaults: RuntimeKeyValueStorage(), identifier: StorageDomainIdentifiers.proposals.rawValue)) {
        self.networkingInteractor = networkingInteractor
        self.kms = kms
        self.metadata = metadata
        self.pairingStore = pairingStore
        self.logger = logger
        self.topicInitializer = topicGenerator
        self.sessionToPairingTopic = sessionToPairingTopic
        self.proposalPayloadsStore = proposalPayloadsStore
        setUpWCRequestHandling()
        setupExpirationHandling()
        restoreSubscriptions()
        networkingInteractor.onPairingResponse = { [weak self] in
            self?.handleResponse($0)
        }
    }
    
    func hasPairing(for topic: String) -> Bool {
        return pairingStore.hasPairing(forTopic: topic)
    }
    
    func getSettledPairing(for topic: String) -> WCPairing? {
        guard let pairing = pairingStore.getPairing(forTopic: topic) else {
            return nil
        }
        return pairing
    }
    
    func getSettledPairings() -> [Pairing] {
        pairingStore.getAll()
            .map {Pairing(topic: $0.topic, peer: $0.peerMetadata, expiryDate: $0.expiryDate)}
    }
    
    func create() async throws -> WalletConnectURI {
        let topic = topicInitializer()
        try await networkingInteractor.subscribe(topic: topic)
        let symKey = try! kms.createSymmetricKey(topic)
        let pairing = WCPairing(topic: topic)
        let uri = WalletConnectURI(topic: topic, symKey: symKey.hexRepresentation, relay: pairing.relay)
        pairingStore.setPairing(pairing)
        return uri
    }
    
    func propose(pairingTopic: String, namespaces: Set<Namespace>, relay: RelayProtocolOptions) async throws {
        logger.debug("Propose Session on topic: \(pairingTopic)")
        let publicKey = try! kms.createX25519KeyPair()
        let proposer = Participant(
            publicKey: publicKey.hexRepresentation,
            metadata: metadata)
        let proposal = SessionProposal(
            relays: [relay],
            proposer: proposer,
            namespaces: namespaces)
        return try await withCheckedThrowingContinuation { continuation in
            networkingInteractor.requestNetworkAck(.wcSessionPropose(proposal), onTopic: pairingTopic) { error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume()
                }
            }
        }
    }

    func ping(topic: String, completion: @escaping ((Result<Void, Error>) -> ())) {
        guard pairingStore.hasPairing(forTopic: topic) else {
            logger.debug("Could not find pairing to ping for topic \(topic)")
            return
        }
        networkingInteractor.requestPeerResponse(.wcPairingPing, onTopic: topic) { [unowned self] result in
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
        networkingInteractor.respondError(for: payload, reason: reason)
//        todo - delete pairing if inactive
    }
    
    func respondSessionPropose(proposerPubKey: String) -> (String, SessionProposal)? {
        guard let payload = try? proposalPayloadsStore.get(key: proposerPubKey),
              case .sessionPropose(let proposal) = payload.wcRequest.params else {
                  //TODO - throws
            return nil
        }
        proposalPayloadsStore.delete(forKey: proposerPubKey)

        let selfPublicKey = try! kms.createX25519KeyPair()
        var agreementKey: AgreementKeys!
        
        do {
            agreementKey = try kms.performKeyAgreement(selfPublicKey: selfPublicKey, peerPublicKey: proposal.proposer.publicKey)
        } catch {
            networkingInteractor.respondError(for: payload, reason: .missingOrInvalid("agreement keys"))
            return nil
        }
        //todo - extend pairing
        let sessionTopic = agreementKey.derivedTopic()

        try! kms.setAgreementSecret(agreementKey, topic: sessionTopic)
        guard let relay = proposal.relays.first else {return nil}
        let proposeResponse = SessionType.ProposeResponse(relay: relay, responderPublicKey: selfPublicKey.hexRepresentation)
        let response = JSONRPCResponse<AnyCodable>(id: payload.wcRequest.id, result: AnyCodable(proposeResponse))
        logger.debug("Responding session propose")
        networkingInteractor.respond(topic: payload.topic, response: .response(response)) { _ in }
        return (sessionTopic, proposal)
    }

    //MARK: - Private

    private func setUpWCRequestHandling() {
        networkingInteractor.wcRequestPublisher.sink { [unowned self] subscriptionPayload in
            switch subscriptionPayload.wcRequest.params {
            case .pairingPing(_):
                wcPairingPing(subscriptionPayload)
            case .sessionPropose(let proposeParams):
                wcSessionPropose(subscriptionPayload, proposal: proposeParams)
            default:
                return
            }
        }.store(in: &publishers)
    }
    
    private func wcSessionPropose(_ payload: WCRequestSubscriptionPayload, proposal: SessionType.ProposeParams) {
        logger.debug("Received Session Proposal")
        try? proposalPayloadsStore.set(payload, forKey: proposal.proposer.publicKey)
        onSessionProposal?(proposal.publicRepresentation())
    }
    
    private func wcPairingPing(_ payload: WCRequestSubscriptionPayload) {
        networkingInteractor.respondSuccess(for: payload)
    }
    
    private func restoreSubscriptions() {
        networkingInteractor.transportConnectionPublisher
            .sink { [unowned self] (_) in
                let topics = pairingStore.getAll()
                    .map{$0.topic}
                topics.forEach{ topic in Task{try? await networkingInteractor.subscribe(topic: topic)}}
            }.store(in: &publishers)
    }
    
    private func setupExpirationHandling() {
        pairingStore.onPairingExpiration = { [weak self] pairing in
            self?.kms.deleteSymmetricKey(for: pairing.topic)
            self?.networkingInteractor.unsubscribe(topic: pairing.topic)
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
            try! sessionToPairingTopic.set(pairingTopic, forKey: sessionTopic)
            onProposeResponse?(sessionTopic)
            
        case .error(let error):
            if !pairing.active {
                kms.deleteSymmetricKey(for: pairing.topic)
                networkingInteractor.unsubscribe(topic: pairing.topic)
                pairingStore.delete(topic: pairingTopic)
            }
            logger.debug("Session Proposal has been rejected")
            kms.deletePrivateKey(for: proposal.proposer.publicKey)
            onSessionRejected?(proposal.publicRepresentation(), SessionType.Reason(code: error.error.code, message: error.error.message))
            return
        }
    }
}
