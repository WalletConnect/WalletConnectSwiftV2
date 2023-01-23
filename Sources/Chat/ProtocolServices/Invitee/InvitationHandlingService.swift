import Foundation
import Combine

class InvitationHandlingService {
    enum Error: Swift.Error {
        case inviteForIdNotFound
    }
    var onInvite: ((Invite) -> Void)?
    var onNewThread: ((Thread) -> Void)?
    private let networkingInteractor: NetworkInteracting
    private let chatStorage: ChatStorage
    private let topicToRegistryRecordStore: CodableStore<RegistryRecord>
    private let registry: Registry
    private let logger: ConsoleLogging
    private let kms: KeyManagementService
    private var publishers = [AnyCancellable]()

    init(registry: Registry,
         networkingInteractor: NetworkInteracting,
         kms: KeyManagementService,
         logger: ConsoleLogging,
         topicToRegistryRecordStore: CodableStore<RegistryRecord>,
         chatStorage: ChatStorage) {
        self.registry = registry
        self.kms = kms
        self.networkingInteractor = networkingInteractor
        self.logger = logger
        self.topicToRegistryRecordStore = topicToRegistryRecordStore
        self.chatStorage = chatStorage
        setUpRequestHandling()
    }

    func accept(inviteId: Int64) async throws {
        guard
            let invite = chatStorage.getInvite(id: inviteId),
            let inviteTopic = chatStorage.getInviteTopic(id: inviteId)
        else { throw Error.inviteForIdNotFound }

        let selfThreadPubKey = try kms.createX25519KeyPair()

        let inviteResponse = InviteResponse(publicKey: selfThreadPubKey.hexRepresentation)

        let responseTopic = try getInviteResponseTopic(
            requestTopic: inviteTopic,
            invite: invite
        )
        try await networkingInteractor.respond(
            topic: responseTopic,
            response: RPCResponse(id: inviteId, result: inviteResponse),
            protocolMethod: ChatInviteProtocolMethod()
        )

        let threadAgreementKeys = try kms.performKeyAgreement(
            selfPublicKey: selfThreadPubKey,
            peerPublicKey: invite.publicKey
        )
        let threadTopic = threadAgreementKeys.derivedTopic()
        try kms.setSymmetricKey(threadAgreementKeys.sharedKey, for: threadTopic)
        try await networkingInteractor.subscribe(topic: threadTopic)

        logger.debug("Accepting an invite on topic: \(threadTopic)")

        // TODO - derive account
        let selfAccount = try! topicToRegistryRecordStore.get(key: inviteTopic)!.account

        let thread = Thread(
            topic: threadTopic,
            selfAccount: selfAccount,
            peerAccount: invite.account
        )

        chatStorage.add(thread: thread)
        chatStorage.delete(invite: invite)

        onNewThread?(thread)
    }

    func reject(inviteId: Int64) async throws {
        guard
            let invite = chatStorage.getInvite(id: inviteId),
            let inviteTopic = chatStorage.getInviteTopic(id: inviteId)
        else { throw Error.inviteForIdNotFound }

        let responseTopic = try getInviteResponseTopic(requestTopic: inviteTopic, invite: invite)

        try await networkingInteractor.respondError(
            topic: responseTopic,
            requestId: RPCID(inviteId),
            protocolMethod: ChatInviteProtocolMethod(),
            reason: ChatError.userRejected
        )

        chatStorage.delete(invite: invite)
    }

    private func setUpRequestHandling() {
        networkingInteractor.requestSubscription(on: ChatInviteProtocolMethod())
            .sink { [unowned self] (payload: RequestSubscriptionPayload<InvitePayload>) in
                logger.debug("did receive an invite")
                onInvite?(Invite(
                    id: payload.id.integer,
                    payload: payload.request
                ))
            }.store(in: &publishers)
    }

    private func getInviteResponseTopic(requestTopic: String, invite: Invite) throws -> String {
        // todo - remove topicToInvitationPubKeyStore ?

        guard let record = try? topicToRegistryRecordStore.get(key: requestTopic) else {
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
