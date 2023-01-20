import Foundation

final class AppProposeService {
    private let metadata: AppMetadata
    private let networkingInteractor: NetworkInteracting
    private let kms: KeyManagementServiceProtocol
    private let logger: ConsoleLogging

    init(
        metadata: AppMetadata,
        networkingInteractor: NetworkInteracting,
        kms: KeyManagementServiceProtocol,
        logger: ConsoleLogging
    ) {
        self.metadata = metadata
        self.networkingInteractor = networkingInteractor
        self.kms = kms
        self.logger = logger
    }

    func propose(pairingTopic: String, namespaces: [String: ProposalNamespace], relay: RelayProtocolOptions) async throws {
        logger.debug("Propose Session on topic: \(pairingTopic)")
        try Namespace.validate(namespaces)
        let protocolMethod = SessionProposeProtocolMethod()
        let publicKey = try! kms.createX25519KeyPair()
        let proposer = Participant(
            publicKey: publicKey.hexRepresentation,
            metadata: metadata)
        
        let proposal = SessionProposal(
            relays: [relay],
            proposer: proposer,
            requiredNamespaces: namespaces)
        
        let request = RPCRequest(method: protocolMethod.method, params: proposal)
        try await networkingInteractor.requestNetworkAck(request, topic: pairingTopic, protocolMethod: protocolMethod)
    }
}
