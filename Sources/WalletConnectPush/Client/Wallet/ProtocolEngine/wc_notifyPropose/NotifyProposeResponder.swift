
import Foundation
import Combine

class NotifyProposeResponder {
    enum Errors: Error {
        case recordForIdNotFound
        case malformedRequestParams
    }
    private let networkingInteractor: NetworkInteracting
    private let kms: KeyManagementServiceProtocol
    private let logger: ConsoleLogging
    private let pushSubscribeRequester: PushSubscribeRequester
    private let rpcHistory: RPCHistory

    private var publishers = [AnyCancellable]()

    init(networkingInteractor: NetworkInteracting,
         kms: KeyManagementServiceProtocol,
         logger: ConsoleLogging,
         pushSubscribeRequester: PushSubscribeRequester,
         rpcHistory: RPCHistory) {
        self.networkingInteractor = networkingInteractor
        self.kms = kms
        self.logger = logger
        self.pushSubscribeRequester = pushSubscribeRequester
        self.rpcHistory = rpcHistory
    }

    func respond(requestId: RPCID, onSign: @escaping SigningCallback) async throws {

        guard let requestRecord = rpcHistory.get(recordId: requestId) else { throw Errors.recordForIdNotFound }
        let proposal = try requestRecord.request.params!.get(NotifyProposeParams.self)

        let subscriptionAuthWrapper = try await pushSubscribeRequester.subscribe(metadata: proposal.metadata, account: proposal.account, onSign: onSign)

        guard let peerPublicKey = try? AgreementPublicKey(hex: proposal.publicKey) else {
            throw Errors.malformedRequestParams
        }

        let responseTopic = peerPublicKey.rawRepresentation.sha256().toHexString()

        let keys = try generateAgreementKeys(peerPublicKey: peerPublicKey)

        let response = RPCResponse(id: requestId, result: subscriptionAuthWrapper)

        let protocolMethod = NotifyProposeProtocolMethod()

        try await networkingInteractor.respond(topic: responseTopic, response: response, protocolMethod: protocolMethod, envelopeType: .type1(pubKey: keys.publicKey.rawRepresentation))
    }

    private func generateAgreementKeys(peerPublicKey: AgreementPublicKey) throws -> AgreementKeys {
        let selfPubKey = try kms.createX25519KeyPair()
        let keys = try kms.performKeyAgreement(selfPublicKey: selfPubKey, peerPublicKey: peerPublicKey.hexRepresentation)
        return keys
    }
}
