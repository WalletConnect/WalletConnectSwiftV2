import Foundation
import Combine

class InvitationHandlingService {

    var onReceivedInvite: ((ReceivedInvite) -> Void)?
    var onNewThread: ((Thread) -> Void)?

    private let keyserverURL: URL
    private let networkingInteractor: NetworkInteracting
    private let identityStorage: IdentityStorage
    private let identityService: IdentityService
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
        identityService: IdentityService,
        accountService: AccountService,
        kms: KeyManagementService,
        logger: ConsoleLogging,
        chatStorage: ChatStorage
    ) {
        self.keyserverURL = keyserverURL
        self.kms = kms
        self.networkingInteractor = networkingInteractor
        self.identityService = identityService
        self.identityStorage = identityStorage
        self.accountService = accountService
        self.logger = logger
        self.chatStorage = chatStorage
        setUpRequestHandling()
    }

    func accept(inviteId: Int64) async throws -> String {
        guard let invite = chatStorage.getReceivedInvite(id: inviteId, account: currentAccount)
        else { throw Errors.inviteForIdNotFound }

        guard let inviteePublicKey = identityStorage.getInviteKey(for: currentAccount)
        else { throw Errors.inviteKeyNotFound }

        let symmetricKey = try kms.performKeyAgreement(selfPublicKey: inviteePublicKey, peerPublicKey: invite.inviterPublicKey)
        let acceptTopic = symmetricKey.derivedTopic()
        try kms.setSymmetricKey(symmetricKey.sharedKey, for: acceptTopic)

        let publicKey = try kms.createX25519KeyPair()
        let jwt = try makeAcceptJWT(publicKey: publicKey.rawRepresentation, inviter: invite.inviterAccount)
        let payload = AcceptPayload(responseAuth: jwt)
        
        try await networkingInteractor.respond(
            topic: acceptTopic,
            response: RPCResponse(id: inviteId, result: payload),
            protocolMethod: ChatInviteProtocolMethod()
        )

        let threadSymmetricKey = try kms.performKeyAgreement(selfPublicKey: publicKey, peerPublicKey: invite.inviteePublicKey)
        let threadTopic = threadSymmetricKey.derivedTopic()
        try kms.setSymmetricKey(threadSymmetricKey.sharedKey, for: threadTopic)
        try await networkingInteractor.subscribe(topic: threadTopic)

        logger.debug("Accepting an invite on topic: \(threadTopic)")

        let thread = Thread(
            topic: threadTopic,
            selfAccount: currentAccount,
            peerAccount: invite.inviteeAccount
        )

        chatStorage.set(thread: thread, account: currentAccount)
        chatStorage.accept(invite: invite, account: currentAccount)

        onNewThread?(thread)

        return thread.topic
    }

    func reject(inviteId: Int64) async throws {
        guard let invite = chatStorage.getReceivedInvite(id: inviteId, account: currentAccount)
        else { throw Errors.inviteForIdNotFound }

        guard let inviteePublicKey = identityStorage.getInviteKey(for: currentAccount)
        else { throw Errors.inviteKeyNotFound }

        let symmetricKey = try kms.performKeyAgreement(selfPublicKey: inviteePublicKey, peerPublicKey: invite.inviterPublicKey)
        let rejectTopic = symmetricKey.derivedTopic()
        try kms.setSymmetricKey(symmetricKey.sharedKey, for: rejectTopic)

        try await networkingInteractor.respondError(
            topic: rejectTopic,
            requestId: RPCID(inviteId),
            protocolMethod: ChatInviteProtocolMethod(),
            reason: ChatError.userRejected
        )

        chatStorage.reject(invite: invite, account: currentAccount)
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

                Task(priority: .high) {
                    let inviterAccount = try await identityService.resolveIdentity(iss: decoded.iss)
                    // TODO: Should we cache it?
                    let inviteePublicKey = try await identityService.resolveInvite(account: inviterAccount)

                    let invite = ReceivedInvite(
                        id: payload.id.integer,
                        message: decoded.message,
                        inviterAccount: inviterAccount,
                        inviteeAccount: decoded.account,
                        inviterPublicKey: decoded.publicKey,
                        inviteePublicKey: inviteePublicKey
                    )
                    chatStorage.set(receivedInvite: invite, account: currentAccount)
                    onReceivedInvite?(invite)
                }
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
