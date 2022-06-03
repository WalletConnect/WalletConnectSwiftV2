import Foundation
import WalletConnectUtils
import WalletConnectKMS

final class ApproveEngine {
    
    private let networkingInteractor: NetworkInteracting
    private let proposalPayloadsStore: CodableStore<WCRequestSubscriptionPayload>
    private let kms: KeyManagementServiceProtocol
    private let logger: ConsoleLogging
    
    init(networkingInteractor: NetworkInteracting,
         proposalPayloadsStore: CodableStore<WCRequestSubscriptionPayload>,
         kms: KeyManagementServiceProtocol,
         logger: ConsoleLogging) {
        self.networkingInteractor = networkingInteractor
        self.proposalPayloadsStore = proposalPayloadsStore
        self.kms = kms
        self.logger = logger
    }
    
    func approveProposal(proposerPubKey: String, validating sessionNamespaces: [String: SessionNamespace]) throws -> (String, SessionProposal) {
        
        let payload = try proposalPayloadsStore.get(key: proposerPubKey)
        
        guard let payload = payload, case .sessionPropose(let proposal) = payload.wcRequest.params
        else { throw ApproveEngineError.wrongRequestParams }

        proposalPayloadsStore.delete(forKey: proposerPubKey)
        
        try Namespace.validate(sessionNamespaces)
        try Namespace.validateApproved(sessionNamespaces, against: proposal.requiredNamespaces)
        
        let selfPublicKey = try kms.createX25519KeyPair()
        let agreementKey = try? kms.performKeyAgreement(selfPublicKey: selfPublicKey, peerPublicKey: proposal.proposer.publicKey)
        guard let agreementKey = agreementKey else {
            networkingInteractor.respondError(for: payload, reason: .missingOrInvalid("agreement keys"))
            throw ApproveEngineError.agreementMissingOrInvalid
        }
        // TODO: Extend pairing
        let sessionTopic = agreementKey.derivedTopic()
        try kms.setAgreementSecret(agreementKey, topic: sessionTopic)

        guard let relay = proposal.relays.first else { throw ApproveEngineError.relayNotFound }
        let proposeResponse = SessionType.ProposeResponse(relay: relay, responderPublicKey: selfPublicKey.hexRepresentation)
        let response = JSONRPCResponse<AnyCodable>(id: payload.wcRequest.id, result: AnyCodable(proposeResponse))
        networkingInteractor.respond(topic: payload.topic, response: .response(response)) { _ in }

        return (sessionTopic, proposal)
    }
}

enum ApproveEngineError: Error {
    case wrongRequestParams
    case relayNotFound
    case agreementMissingOrInvalid
}
