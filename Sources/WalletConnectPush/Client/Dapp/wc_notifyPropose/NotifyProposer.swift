
import Foundation

class NotifyProposer {
    private let networkingInteractor: NetworkInteracting
    private let kms: KeyManagementService
    private let logger: ConsoleLogging
    private let metadata: AppMetadata

    init(networkingInteractor: NetworkInteracting,
         kms: KeyManagementService,
         appMetadata: AppMetadata,
         logger: ConsoleLogging) {
        self.networkingInteractor = networkingInteractor
        self.kms = kms
        self.metadata = appMetadata
        self.logger = logger
    }

    func propose(topic: String, account: Account) async throws {
        logger.debug("NotifyProposer: Sending Notify Proposal")
        let protocolMethod = NotifyProposeProtocolMethod()
        let publicKey = try kms.createX25519KeyPair()
        let responseTopic = publicKey.rawRepresentation.sha256().toHexString()
        try kms.setPublicKey(publicKey: publicKey, for: responseTopic)

        let params = NotifyProposeParams(publicKey: publicKey.hexRepresentation, metadata: metadata, account: account, scope: [])
        let request = RPCRequest(method: protocolMethod.method, params: params)
        try await networkingInteractor.request(request, topic: topic, protocolMethod: protocolMethod)
        try await networkingInteractor.subscribe(topic: responseTopic)
    }

}
