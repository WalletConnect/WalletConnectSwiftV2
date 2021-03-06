import Foundation
import WalletConnectKMS
import WalletConnectUtils
import WalletConnectRelay
import Combine

class InvitationHandlingService {
    enum Error: Swift.Error {
        case inviteForIdNotFound
    }
    var onInvite: ((Invite) -> Void)?
    var onNewThread: ((Thread) -> Void)?
    private let networkingInteractor: NetworkInteracting
    private let invitePayloadStore: CodableStore<(RequestSubscriptionPayload)>
    private let topicToRegistryRecordStore: CodableStore<RegistryRecord>
    private let registry: Registry
    private let logger: ConsoleLogging
    private let kms: KeyManagementService
    private let threadsStore: Database<Thread>
    private var publishers = [AnyCancellable]()

    init(registry: Registry,
         networkingInteractor: NetworkInteracting,
         kms: KeyManagementService,
         logger: ConsoleLogging,
         topicToRegistryRecordStore: CodableStore<RegistryRecord>,
         invitePayloadStore: CodableStore<RequestSubscriptionPayload>,
         threadsStore: Database<Thread>) {
        self.registry = registry
        self.kms = kms
        self.networkingInteractor = networkingInteractor
        self.logger = logger
        self.topicToRegistryRecordStore = topicToRegistryRecordStore
        self.invitePayloadStore = invitePayloadStore
        self.threadsStore = threadsStore
        setUpRequestHandling()
    }

    func accept(inviteId: String) async throws {

        guard let payload = try invitePayloadStore.get(key: inviteId) else { throw Error.inviteForIdNotFound }

        let selfThreadPubKey = try kms.createX25519KeyPair()

        let inviteResponse = InviteResponse(publicKey: selfThreadPubKey.hexRepresentation)

        let response = JsonRpcResult.response(JSONRPCResponse<AnyCodable>(id: payload.request.id, result: AnyCodable(inviteResponse)))

        guard case .invite(let invite) = payload.request.params else {return}

        let responseTopic = try getInviteResponseTopic(payload, invite)

        try await networkingInteractor.respond(topic: responseTopic, response: response, tag: payload.request.params.responseTag)

        let threadAgreementKeys = try kms.performKeyAgreement(selfPublicKey: selfThreadPubKey, peerPublicKey: invite.publicKey)

        let threadTopic = threadAgreementKeys.derivedTopic()

        try kms.setSymmetricKey(threadAgreementKeys.sharedKey, for: threadTopic)

        try await networkingInteractor.subscribe(topic: threadTopic)

        logger.debug("Accepting an invite on topic: \(threadTopic)")

        // TODO - derive account
        let selfAccount = try! topicToRegistryRecordStore.get(key: payload.topic)!.account
        let thread = Thread(topic: threadTopic, selfAccount: selfAccount, peerAccount: invite.account)
        await threadsStore.add(thread)

        invitePayloadStore.delete(forKey: inviteId)

        onNewThread?(thread)
    }

    func reject(inviteId: String) async throws {

        guard let payload = try invitePayloadStore.get(key: inviteId) else { throw Error.inviteForIdNotFound }

        guard case .invite(let invite) = payload.request.params else {return}

        let responseTopic = try getInviteResponseTopic(payload, invite)

        // TODO - error not in specs yet
        let error = JSONRPCErrorResponse.Error(code: 0, message: "user rejected")
        let response = JsonRpcResult.error(JSONRPCErrorResponse(id: payload.request.id, error: error))

        try await networkingInteractor.respond(topic: responseTopic, response: response, tag: payload.request.params.responseTag)

        invitePayloadStore.delete(forKey: inviteId)
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
        invitePayloadStore.set(payload, forKey: invite.publicKey)
        onInvite?(invite)
    }

    private func getInviteResponseTopic(_ payload: RequestSubscriptionPayload, _ invite: Invite) throws -> String {
        // todo - remove topicToInvitationPubKeyStore ?

        guard let record = try? topicToRegistryRecordStore.get(key: payload.topic) else {
            logger.debug("PubKey for invitation topic not found")
            fatalError("todo")
        }

        let selfPubKey = try AgreementPublicKey(hex: record.pubKey)

        let agreementKeysI = try kms.performKeyAgreement(selfPublicKey: selfPubKey, peerPublicKey: invite.publicKey)

        // agreement keys already stored by serializer
        let responseTopic = agreementKeysI.derivedTopic()
        return responseTopic
    }
}
