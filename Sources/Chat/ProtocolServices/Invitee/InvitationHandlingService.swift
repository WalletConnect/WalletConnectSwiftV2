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
    private let logger: ConsoleLogging
    private let kms: KeyManagementService
    private var publishers = [AnyCancellable]()

    private var currentAccount: Account {
        return accountService.currentAccount
    }

    init(
        keyserverURL: URL,
        networkingInteractor: NetworkInteracting,
        identityStorage: IdentityStorage,
        accountService: AccountService,
        kms: KeyManagementService,
        logger: ConsoleLogging,
        chatStorage: ChatStorage
    ) {
        self.keyserverURL = keyserverURL
        self.kms = kms
        self.networkingInteractor = networkingInteractor
        self.identityStorage = identityStorage
        self.accountService = accountService
        self.logger = logger
        self.chatStorage = chatStorage
        setUpRequestHandling()
    }

    func accept(inviteId: Int64) async throws {
        guard let invite = chatStorage.getInvite(id: inviteId, account: currentAccount)
        else { throw Errors.inviteForIdNotFound }

        guard let inviteePublicKey = identityStorage.getInviteKey(for: currentAccount)
        else { throw Errors.inviteKeyNotFound }

        let symmetricKey = try kms.performKeyAgreement(selfPublicKey: inviteePublicKey, peerPublicKey: invite.publicKey)
        let acceptTopic = symmetricKey.derivedTopic()
        try kms.setSymmetricKey(symmetricKey.sharedKey, for: acceptTopic)

        let publicKey = try kms.createX25519KeyPair()
        let jwt = try makeAcceptJWT(publicKey: publicKey.rawRepresentation, inviter: invite.account)
        let payload = AcceptPayload(responseAuth: jwt)
        
        try await networkingInteractor.respond(
            topic: acceptTopic,
            response: RPCResponse(id: inviteId, result: payload),
            protocolMethod: ChatInviteProtocolMethod()
        )

        let threadSymmetricKey = try kms.performKeyAgreement(selfPublicKey: publicKey, peerPublicKey: invite.publicKey)
        let threadTopic = threadSymmetricKey.derivedTopic()
        try kms.setSymmetricKey(threadSymmetricKey.sharedKey, for: threadTopic)
        try await networkingInteractor.subscribe(topic: threadTopic)

        logger.debug("Accepting an invite on topic: \(threadTopic)")

        let thread = Thread(
            topic: threadTopic,
            selfAccount: currentAccount,
            peerAccount: invite.account
        )

        chatStorage.set(thread: thread, account: currentAccount)
        chatStorage.delete(invite: invite, account: currentAccount)

        onNewThread?(thread)
    }

    func reject(inviteId: Int64) async throws {
        guard let invite = chatStorage.getInvite(id: inviteId, account: currentAccount)
        else { throw Errors.inviteForIdNotFound }

        guard let inviteePublicKey = identityStorage.getInviteKey(for: currentAccount)
        else { throw Errors.inviteKeyNotFound }

        let symmetricKey = try kms.performKeyAgreement(selfPublicKey: inviteePublicKey, peerPublicKey: invite.publicKey)
        let rejectTopic = symmetricKey.derivedTopic()
        try kms.setSymmetricKey(symmetricKey.sharedKey, for: rejectTopic)

        try await networkingInteractor.respondError(
            topic: rejectTopic,
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
        case inviteKeyNotFound
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

    func makeAcceptJWT(publicKey: Data, inviter: Account) throws -> String {
        guard let identityKey = identityStorage.getIdentityKey(for: accountService.currentAccount)
        else { throw Errors.identityKeyNotFound }

        return try JWTFactory(keyPair: identityKey).createChatInviteApprovalJWT(
            ksu: keyserverURL.absoluteString,
            aud: inviter.did,
            sub: DIDKey(rawData: publicKey).did(prefix: true)
        )
    }
}
