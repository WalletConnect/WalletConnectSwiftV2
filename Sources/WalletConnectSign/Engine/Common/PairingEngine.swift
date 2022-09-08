import Foundation
import Combine
import JSONRPC
import WalletConnectPairing
import WalletConnectUtils
import WalletConnectKMS
import WalletConnectNetworking

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

    func getPairings() -> [Pairing] {
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

        let request = RPCRequest(method: SignProtocolMethod.sessionPropose.method, params: proposal)
        try await networkingInteractor.request(request, topic: pairingTopic, tag: SignProtocolMethod.sessionPropose.requestTag)
    }
}

// MARK: Private

private extension PairingEngine {

    func setupNetworkingSubscriptions() {
        networkingInteractor.socketConnectionStatusPublisher
            .sink { [unowned self] status in
                guard status == .connected else { return }
                pairingStore.getAll()
                    .forEach { pairing in
                        Task(priority: .high) { try await networkingInteractor.subscribe(topic: pairing.topic) }
                    }
            }
            .store(in: &publishers)

        networkingInteractor.requestSubscription(on: SignProtocolMethod.pairingPing)
            .sink { [unowned self] (payload: RequestSubscriptionPayload<PairingType.PingParams>) in
                Task(priority: .high) {
                    try await networkingInteractor.respondSuccess(topic: payload.topic, requestId: payload.id, tag: SignProtocolMethod.pairingPing.responseTag)
                }
            }
            .store(in: &publishers)
    }

    func setupExpirationHandling() {
        pairingStore.onPairingExpiration = { [weak self] pairing in
            self?.kms.deleteSymmetricKey(for: pairing.topic)
            self?.networkingInteractor.unsubscribe(topic: pairing.topic)
        }
    }
}
