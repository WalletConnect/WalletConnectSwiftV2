import Foundation
import Combine
import WalletConnectPairing

class PushProposer {
    private let networkingInteractor: NetworkInteracting
    private let kms: KeyManagementServiceProtocol
    private let appMetadata: AppMetadata
    private let logger: ConsoleLogging

    init(networkingInteractor: NetworkInteracting,
         kms: KeyManagementServiceProtocol,
         appMetadata: AppMetadata,
         logger: ConsoleLogging) {
        self.networkingInteractor = networkingInteractor
        self.kms = kms
        self.logger = logger
        self.appMetadata = appMetadata
    }

    func request(topic: String, account: Account) async throws {
        logger.debug("PushProposer: Sending Push Proposal")
        let protocolMethod = PushProposeProtocolMethod()
        let pubKey = try kms.createX25519KeyPair()
        let responseTopic = pubKey.rawRepresentation.sha256().toHexString()
        let params = PushRequestParams(publicKey: pubKey.hexRepresentation, metadata: appMetadata, account: account)
        try kms.setPublicKey(publicKey: pubKey, for: responseTopic)
        let request = RPCRequest(method: protocolMethod.method, params: params)
        try await networkingInteractor.request(request, topic: topic, protocolMethod: protocolMethod)
    }
}
