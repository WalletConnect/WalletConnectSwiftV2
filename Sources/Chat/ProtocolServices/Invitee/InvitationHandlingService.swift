import Foundation
import Combine

class InvitationHandlingService {
    enum Error: Swift.Error {
        case inviteForIdNotFound
    }
    var onInvite: ((Invite) -> Void)?
    var onNewThread: ((Thread) -> Void)?
    private let networkingInteractor: NetworkInteracting
    private let invitePayloadStore: CodableStore<RequestSubscriptionPayload<Invite>>
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
         invitePayloadStore: CodableStore<RequestSubscriptionPayload<Invite>>,
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
        let protocolMethod = ChatInviteProtocolMethod()

        guard let payload = try invitePayloadStore.get(key: inviteId) else { throw Error.inviteForIdNotFound }

        let selfThreadPubKey = try kms.createX25519KeyPair()

        let inviteResponse = InviteResponse(publicKey: selfThreadPubKey.hexRepresentation)

        let response = RPCResponse(id: payload.id, result: inviteResponse)
        let responseTopic = try getInviteResponseTopic(requestTopic: payload.topic, invite: payload.request)
        try await networkingInteractor.respond(topic: responseTopic, response: response, protocolMethod: protocolMethod)

        let threadAgreementKeys = try kms.performKeyAgreement(selfPublicKey: selfThreadPubKey, peerPublicKey: payload.request.publicKey)
        let threadTopic = threadAgreementKeys.derivedTopic()
        try kms.setSymmetricKey(threadAgreementKeys.sharedKey, for: threadTopic)
        try await networkingInteractor.subscribe(topic: threadTopic)

        logger.debug("Accepting an invite on topic: \(threadTopic)")

        // TODO - derive account
        let selfAccount = try! topicToRegistryRecordStore.get(key: payload.topic)!.account
        let thread = Thread(topic: threadTopic, selfAccount: selfAccount, peerAccount: payload.request.account)
        await threadsStore.add(thread)

        invitePayloadStore.delete(forKey: inviteId)

        onNewThread?(thread)
    }

    func reject(inviteId: String) async throws {
        guard let payload = try invitePayloadStore.get(key: inviteId) else { throw Error.inviteForIdNotFound }

        let responseTopic = try getInviteResponseTopic(requestTopic: payload.topic, invite: payload.request)

        try await networkingInteractor.respondError(topic: responseTopic, requestId: payload.id, protocolMethod: ChatInviteProtocolMethod(), reason: ChatError.userRejected)

        invitePayloadStore.delete(forKey: inviteId)
    }

    private func setUpRequestHandling() {
        networkingInteractor.requestSubscription(on: ChatInviteProtocolMethod())
            .sink { [unowned self] (payload: RequestSubscriptionPayload<Invite>) in
                logger.debug("did receive an invite")
                invitePayloadStore.set(payload, forKey: payload.request.publicKey)
                onInvite?(payload.request)
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
