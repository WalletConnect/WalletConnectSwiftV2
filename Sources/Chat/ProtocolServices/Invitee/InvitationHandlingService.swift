
import Foundation
import WalletConnectKMS
import WalletConnectUtils
import WalletConnectRelay
import Combine

class InvitationHandlingService {
    enum Error: Swift.Error {
        case inviteForIdNotFound
    }
    var onInvite: ((InviteEnvelope)->())?
    var onNewThread: ((String)->())?
    private let networkingInteractor: NetworkInteracting
    private let invitePayloadStore: CodableStore<(RequestSubscriptionPayload)>
    private let topicToInvitationPubKeyStore: CodableStore<String>
    private let registry: Registry
    private let logger: ConsoleLogging
    private let kms: KeyManagementService
    private let threadsStore: CodableStore<Thread>
    private var publishers = [AnyCancellable]()
    private let codec: Codec
    
    init(registry: Registry,
         networkingInteractor: NetworkInteracting,
         kms: KeyManagementService,
         logger: ConsoleLogging,
         topicToInvitationPubKeyStore: CodableStore<String>,
         invitePayloadStore: CodableStore<RequestSubscriptionPayload>,
         threadsStore: CodableStore<Thread>,
         codec: Codec) {
        self.registry = registry
        self.kms = kms
        self.networkingInteractor = networkingInteractor
        self.logger = logger
        self.topicToInvitationPubKeyStore = topicToInvitationPubKeyStore
        self.invitePayloadStore = invitePayloadStore
        self.threadsStore = threadsStore
        self.codec = codec
        setUpRequestHandling()
        setUpResponseHandling()
    }

    func accept(inviteId: String) async throws {
        
        guard let payload = try invitePayloadStore.get(key: inviteId) else { throw Error.inviteForIdNotFound }
        
        let selfThreadPubKey = try kms.createX25519KeyPair()
        
        let inviteResponse = InviteResponse(pubKey: selfThreadPubKey.hexRepresentation)
        
        let response = JsonRpcResult.response(JSONRPCResponse<AnyCodable>(id: payload.request.id, result: AnyCodable(inviteResponse)))
        
        try await networkingInteractor.respond(topic: payload.topic, response: response)
        
        guard case .invite(let inviteParams) = payload.request.params else {return}
        
        let threadAgreementKeys = try kms.performKeyAgreement(selfPublicKey: selfThreadPubKey, peerPublicKey: inviteParams.pubKey)
        
        let threadTopic = threadAgreementKeys.derivedTopic()
        
        try await networkingInteractor.subscribe(topic: threadTopic)
        
        logger.debug("Accepting an invite")
        
        onNewThread?(threadTopic)
    }

    private func setUpRequestHandling() {
        networkingInteractor.requestPublisher.sink { [unowned self] subscriptionPayload in
            switch subscriptionPayload.request.params {
            case .invite(let invite):
                do {
                    try handleInvite(invite, subscriptionPayload)
                } catch {
                    logger.debug("Did not handle invite, error: \(error)")
                }
            case .message(let message):
                print("received message: \(message)")
            }
        }.store(in: &publishers)
    }

    private func handleInvite(_ inviteParams: InviteParams, _ payload: RequestSubscriptionPayload) throws {
        logger.debug("did receive an invite")
        guard let selfPubKeyHex = try? topicToInvitationPubKeyStore.get(key: payload.topic) else {
            logger.debug("PubKey for invitation topic not found")
            return
        }
        
        let selfPubKey = try AgreementPublicKey(hex: selfPubKeyHex)
        
        let agreementKeysI = try kms.performKeyAgreement(selfPublicKey: selfPubKey, peerPublicKey: inviteParams.pubKey)
                        
        let decryptedData = try codec.decode(sealboxString: inviteParams.invite, symmetricKey: agreementKeysI.sharedKey.rawRepresentation)
        
        let invite = try JSONDecoder().decode(Invite.self, from: decryptedData)
        
        try kms.setSymmetricKey(agreementKeysI.sharedKey, for: payload.topic)
        
        invitePayloadStore.set(payload, forKey: inviteParams.id)
                
        onInvite?(InviteEnvelope(pubKey: inviteParams.pubKey, invite: invite))
    }
}
