import Foundation
import Combine
import WalletConnectPairing
import WalletConnectUtils
import WalletConnectKMS

final class PairingEngine {

    private let networkingInteractor: NetworkInteracting
    private let kms: KeyManagementServiceProtocol
    private let pairingStore: WCPairingStorage
    private var metadata: AppMetadata
    private var publishers = [AnyCancellable]()
    private let logger: ConsoleLogging
    private let topicInitializer: () -> String

    init(
        networkingInteractor: NetworkInteracting,
        kms: KeyManagementServiceProtocol,
        pairingStore: WCPairingStorage,
        metadata: AppMetadata,
        logger: ConsoleLogging,
        topicGenerator: @escaping () -> String = String.generateTopic
    ) {
        self.networkingInteractor = networkingInteractor
        self.kms = kms
        self.metadata = metadata
        self.pairingStore = pairingStore
        self.logger = logger
        self.topicInitializer = topicGenerator
        setupNetworkingSubscriptions()
        setupExpirationHandling()
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

    func propose(pairingTopic: String, namespaces: [String: ProposalNamespace], relay: RelayProtocolOptions) async throws {
        logger.debug("Propose Session on topic: \(pairingTopic)")
        try Namespace.validate(namespaces)
        let publicKey = try! kms.createX25519KeyPair()
        let proposer = Participant(
            publicKey: publicKey.hexRepresentation,
            metadata: metadata)
        let proposal = SessionProposal(
            relays: [relay],
            proposer: proposer,
            requiredNamespaces: namespaces)
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

    func ping(topic: String, completion: @escaping ((Result<Void, Error>) -> Void)) {
        guard pairingStore.hasPairing(forTopic: topic) else {
            logger.debug("Could not find pairing to ping for topic \(topic)")
            return
        }
        networkingInteractor.requestPeerResponse(.wcPairingPing, onTopic: topic) { [unowned self] result in
            switch result {
            case .success:
                logger.debug("Did receive ping response")
                completion(.success(()))
            case .failure(let error):
                logger.debug("error: \(error)")
            }
        }
    }
}

// MARK: Private

private extension PairingEngine {

    func setupNetworkingSubscriptions() {
        networkingInteractor.transportConnectionPublisher
            .sink { [unowned self] (_) in
                let topics = pairingStore.getAll()
                    .map {$0.topic}
                topics.forEach { topic in Task {try? await networkingInteractor.subscribe(topic: topic)}}
            }.store(in: &publishers)

        networkingInteractor.wcRequestPublisher
            .sink { [unowned self] subscriptionPayload in
                switch subscriptionPayload.wcRequest.params {
                case .pairingPing:
                    wcPairingPing(subscriptionPayload)
                default:
                    return
                }
            }.store(in: &publishers)
    }

    func wcPairingPing(_ payload: WCRequestSubscriptionPayload) {
        networkingInteractor.respondSuccess(for: payload)
    }

    func setupExpirationHandling() {
        pairingStore.onPairingExpiration = { [weak self] pairing in
            self?.kms.deleteSymmetricKey(for: pairing.topic)
            self?.networkingInteractor.unsubscribe(topic: pairing.topic)
        }
    }
}
