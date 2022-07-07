import Foundation
import WalletConnectKMS
import WalletConnectUtils
import WalletConnectRelay
import Combine

class InvitationHandlingService {
    enum Error: Swift.Error {
        case inviteForIdNotFound
    }
    var onInvite: ((InviteEnvelope) -> Void)?
    var onNewThread: ((Thread) -> Void)?
    private let networkingInteractor: NetworkInteracting
    private let invitePayloadStore: CodableStore<(RequestSubscriptionPayload)>
    private let topicToInvitationPubKeyStore: CodableStore<String>
    private let registry: Registry
    private let logger: ConsoleLogging
    private let kms: KeyManagementService
    private let threadsStore: Database<Thread>
    private var publishers = [AnyCancellable]()

    init(registry: Registry,
         networkingInteractor: NetworkInteracting,
         kms: KeyManagementService,
         logger: ConsoleLogging,
         topicToInvitationPubKeyStore: CodableStore<String>,
         invitePayloadStore: CodableStore<RequestSubscriptionPayload>,
         threadsStore: Database<Thread>) {
        self.registry = registry
        self.kms = kms
        self.networkingInteractor = networkingInteractor
        self.logger = logger
        self.topicToInvitationPubKeyStore = topicToInvitationPubKeyStore
        self.invitePayloadStore = invitePayloadStore
        self.threadsStore = threadsStore
        setUpRequestHandling()
    }

    func accept(inviteId: String) async throws {

        guard let payload = try invitePayloadStore.get(key: inviteId) else { throw Error.inviteForIdNotFound }

        let selfThreadPubKey = try kms.createX25519KeyPair()

        let inviteResponse = InviteResponse(pubKey: selfThreadPubKey.hexRepresentation)

        let response = JsonRpcResult.response(JSONRPCResponse<AnyCodable>(id: payload.request.id, result: AnyCodable(inviteResponse)))

        guard case .invite(let invite) = payload.request.params else {return}

        let responseTopic = try getInviteResponseTopic(payload, invite)

        try await networkingInteractor.respond(topic: responseTopic, response: response)

        let threadAgreementKeys = try kms.performKeyAgreement(selfPublicKey: selfThreadPubKey, peerPublicKey: invite.pubKey)

        let threadTopic = threadAgreementKeys.derivedTopic()

        try kms.setSymmetricKey(threadAgreementKeys.sharedKey, for: threadTopic)

        try await networkingInteractor.subscribe(topic: threadTopic)

        logger.debug("Accepting an invite")

        let thread = Thread(topic: threadTopic)
        Task(priority: .background) {
            threadsStore.add(thread)
        }

        onNewThread?(thread)
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
            default:
                return
            }
        }.store(in: &publishers)
    }

    private func handleInvite(_ invite: Invite, _ payload: RequestSubscriptionPayload) throws {
        logger.debug("did receive an invite")
        invitePayloadStore.set(payload, forKey: invite.pubKey)
        onInvite?(InviteEnvelope(pubKey: invite.pubKey, invite: invite))
    }

    private func getInviteResponseTopic(_ payload: RequestSubscriptionPayload, _ invite: Invite) throws -> String {
        //todo - remove topicToInvitationPubKeyStore ?

        guard let selfPubKeyHex = try? topicToInvitationPubKeyStore.get(key: payload.topic) else {
            logger.debug("PubKey for invitation topic not found")
            fatalError("todo")
        }

        let selfPubKey = try AgreementPublicKey(hex: selfPubKeyHex)

        let agreementKeysI = try kms.performKeyAgreement(selfPublicKey: selfPubKey, peerPublicKey: invite.pubKey)

        // agreement keys already stored by serializer
        let responseTopic = agreementKeysI.derivedTopic()
        return responseTopic
    }

}
