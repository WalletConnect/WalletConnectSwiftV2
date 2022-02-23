import Foundation
import Combine
import WalletConnectUtils
import WalletConnectKMS

final class PairingEngine {
    var onApprovalAcknowledgement: ((Pairing) -> Void)?
    var onSessionProposal: ((SessionProposal)->())?
    var onPairingApproved: ((Pairing, SessionPermissions, RelayProtocolOptions)->())?
    var onPairingExtend: ((Pairing)->())?
    
    private let wcSubscriber: WCSubscribing
    private let relayer: WalletConnectRelaying
    private let kms: KeyManagementServiceProtocol
    private let sequencesStore: PairingSequenceStorage
    private var appMetadata: AppMetadata
    private var publishers = [AnyCancellable]()
    private let logger: ConsoleLogging
    private var sessionPermissions: [String: SessionPermissions] = [:]
    private let topicInitializer: () -> String?
    
    init(relay: WalletConnectRelaying,
         kms: KeyManagementServiceProtocol,
         subscriber: WCSubscribing,
         sequencesStore: PairingSequenceStorage,
         metadata: AppMetadata,
         logger: ConsoleLogging,
         topicGenerator: @escaping () -> String? = String.generateTopic) {
        self.relayer = relay
        self.kms = kms
        self.wcSubscriber = subscriber
        self.appMetadata = metadata
        self.sequencesStore = sequencesStore
        self.logger = logger
        self.topicInitializer = topicGenerator
        setUpWCRequestHandling()
        setupExpirationHandling()
        restoreSubscriptions()
        
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
        let symKey = try! kms.createSymmetricKey()
        let topic = symKey.derivedTopic()
        let pairing = PairingSequence.build(topic)
        let uri = WalletConnectURI(topic: topic, symKey: symKey.hexRepresentation, relay: pairing.relay)
        sequencesStore.setSequence(pairing)
        wcSubscriber.setSubscription(topic: topic)
        return uri
    }
    
    func pair(_ uri: WalletConnectURI) {
        
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
    
    func extend(topic: String, ttl: Int) throws {
        guard var pairing = sequencesStore.getSequence(forTopic: topic) else {
            throw WalletConnectError.noPairingMatchingTopic(topic)
        }
        try pairing.extend(ttl)
        sequencesStore.setSequence(pairing)
        relayer.request(.wcPairingExtend(PairingType.ExtendParams(ttl: ttl)), onTopic: topic)
    }
    
    //MARK: - Private

    private func setUpWCRequestHandling() {
        wcSubscriber.onReceivePayload = { [unowned self] subscriptionPayload in
            switch subscriptionPayload.wcRequest.params {
            case .pairingPing(_):
                wcPairingPing(subscriptionPayload)
            case .pairingExtend(_):
                //TODO - extend and delete
                break
            default:
                logger.warn("Warning: Pairing Engine - Unexpected method type: \(subscriptionPayload.wcRequest.method) received from subscriber")
            }
        }
    }
    
    
    private func wcPairingExtend(_ payload: WCRequestSubscriptionPayload, extendParams: PairingType.ExtendParams) {
        let topic = payload.topic
        guard var pairing = sequencesStore.getSequence(forTopic: topic) else {
            relayer.respondError(for: payload, reason: .noContextWithTopic(context: .pairing, topic: topic))
            return
        }
        do {
            try pairing.extend(extendParams.ttl)
        } catch {
            relayer.respondError(for: payload, reason: .invalidExtendRequest(context: .pairing))
            return
        }
        sequencesStore.setSequence(pairing)
        relayer.respondSuccess(for: payload)
        onPairingExtend?(Pairing(topic: pairing.topic, peer: pairing.state?.metadata, expiryDate: pairing.expiryDate))
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
        sequencesStore.onSequenceExpiration = { [weak self] topic, _ in
            self?.kms.deleteSymmetricKey(for: topic)
        }
    }
    
}
