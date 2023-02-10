import Foundation
import Combine

class InvitationHandlingService {

    var onInvite: ((Invite) -> Void)?
    var onNewThread: ((Thread) -> Void)?

    private let keyserverURL: URL
    private let networkingInteractor: NetworkInteracting
    private let identityStorage: IdentityStorage
    private let chatStorage: ChatStorage
    private let accountService: AccountService
    private let topicToRegistryRecordStore: CodableStore<RegistryRecord>
    private let registry: Registry
    private let logger: ConsoleLogging
    private let kms: KeyManagementService
    private var publishers = [AnyCancellable]()

    private var currentAccount: Account {
        return accountService.currentAccount
    }

    init(
        keyserverURL: URL,
        registry: Registry,
        networkingInteractor: NetworkInteracting,
        identityStorage: IdentityStorage,
        accountService: AccountService,
        kms: KeyManagementService,
        logger: ConsoleLogging,
        topicToRegistryRecordStore: CodableStore<RegistryRecord>,
        chatStorage: ChatStorage
    ) {
        self.keyserverURL = keyserverURL
        self.registry = registry
        self.kms = kms
        self.networkingInteractor = networkingInteractor
        self.identityStorage = identityStorage
        self.accountService = accountService
        self.logger = logger
        self.topicToRegistryRecordStore = topicToRegistryRecordStore
        self.chatStorage = chatStorage
        setUpRequestHandling()
    }

    func accept(inviteId: Int64) async throws {
        guard
            let invite = chatStorage.getInvite(id: inviteId, account: currentAccount),
            let inviteTopic = chatStorage.getInviteTopic(id: inviteId, account: currentAccount)
        else { throw Errors.inviteForIdNotFound }

        let selfThreadPubKey = try kms.createX25519KeyPair()
        let responseTopic = try getInviteResponseTopic(requestTopic: inviteTopic, invite: invite)
        let jwt = try makeAcceptJWT(publicKey: selfThreadPubKey.rawRepresentation)
        let payload = AcceptPayload(responseAuth: jwt)

        try await networkingInteractor.respond(
            topic: responseTopic,
            response: RPCResponse(id: inviteId, result: payload),
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

        // TODO: - derive account
        let selfAccount = try! topicToRegistryRecordStore.get(key: inviteTopic)!.account

        let thread = Thread(
            topic: threadTopic,
            selfAccount: selfAccount,
            peerAccount: invite.account
        )

        chatStorage.set(thread: thread, account: currentAccount)
        chatStorage.delete(invite: invite, account: currentAccount)

        onNewThread?(thread)
    }

    func reject(inviteId: Int64) async throws {
        guard
            let invite = chatStorage.getInvite(id: inviteId, account: currentAccount),
            let inviteTopic = chatStorage.getInviteTopic(id: inviteId, account: currentAccount)
        else { throw Errors.inviteForIdNotFound }

        let responseTopic = try getInviteResponseTopic(requestTopic: inviteTopic, invite: invite)

        try await networkingInteractor.respondError(
            topic: responseTopic,
            requestId: RPCID(inviteId),
            protocolMethod: ChatInviteProtocolMethod(),
            reason: ChatError.userRejected
        )

        chatStorage.delete(invite: invite, account: currentAccount)
    }
}

private extension InvitationHandlingService {

    enum Errors: Error {
        case inviteForIdNotFound
        case identityKeyNotFound
    }

    func setUpRequestHandling() {
        networkingInteractor.requestSubscription(on: ChatInviteProtocolMethod())
            .sink { [unowned self] (payload: RequestSubscriptionPayload<InvitePayload>) in
                logger.debug("Did receive an invite")

                guard let decoded = try? payload.request.decode()
                else { fatalError() /* TODO: Handle error */ }

                let invite = Invite(
                    id: payload.id.integer,
                    topic: payload.topic,
                    message: decoded.message,
                    account: decoded.account,
                    publicKey: decoded.publicKey
                )
                chatStorage.set(invite: invite, account: currentAccount)
                onInvite?(invite)
            }.store(in: &publishers)
    }

    func getInviteResponseTopic(requestTopic: String, invite: Invite) throws -> String {
        // TODO: - remove topicToInvitationPubKeyStore ?

        guard let record = try? topicToRegistryRecordStore.get(key: requestTopic)
        else { fatalError() /* TODO: Handle error */ }

        let selfPubKey = try AgreementPublicKey(hex: record.pubKey)

        let agreementKeysI = try kms.performKeyAgreement(selfPublicKey: selfPubKey, peerPublicKey: invite.publicKey)

        // agreement keys already stored by serializer
        let responseTopic = agreementKeysI.derivedTopic()
        return responseTopic
    }

    func makeAcceptJWT(publicKey: Data) throws -> String {
        guard let identityKey = identityStorage.getIdentityKey(for: accountService.currentAccount)
        else { throw Errors.identityKeyNotFound }

        return try JWTFactory(keyPair: identityKey).createChatInviteApprovalJWT(
            ksu: keyserverURL.absoluteString,
            aud: accountService.currentAccount.did,
            sub: DIDKey(rawData: publicKey).did(prefix: true)
        )
    }
}
