import Foundation
import Combine

class InvitationHandlingService {

    private let keyserverURL: URL
    private let networkingInteractor: NetworkInteracting
    private let identityClient: IdentityClient
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
        identityClient: IdentityClient,
        accountService: AccountService,
        kms: KeyManagementService,
        logger: ConsoleLogging,
        chatStorage: ChatStorage
    ) {
        self.keyserverURL = keyserverURL
        self.kms = kms
        self.networkingInteractor = networkingInteractor
        self.identityClient = identityClient
        self.accountService = accountService
        self.logger = logger
        self.chatStorage = chatStorage
        setUpRequestHandling()
    }

    func accept(inviteId: Int64) async throws -> String {
        guard let invite = chatStorage.getReceivedInvite(id: inviteId, account: currentAccount)
        else { throw Errors.inviteForIdNotFound }

        let inviteePublicKey = try identityClient.getInviteKey(for: currentAccount)
        let inviterPublicKey = try DIDKey(did: invite.inviterPublicKey).hexString

        let symmetricKey = try kms.performKeyAgreement(selfPublicKey: inviteePublicKey, peerPublicKey: inviterPublicKey)
        let acceptTopic = symmetricKey.derivedTopic()
        try kms.setSymmetricKey(symmetricKey.sharedKey, for: acceptTopic)

        let publicKey = try kms.createX25519KeyPair()

        let payload = AcceptPayload(
            keyserver: keyserverURL,
            inviterAccount: invite.inviterAccount,
            inviteePublicKey: DIDKey(rawData: publicKey.rawRepresentation)
        )
        let wrapper = try identityClient.signAndCreateWrapper(
            payload: payload,
            account: currentAccount
        )
        try await networkingInteractor.respond(
            topic: acceptTopic,
            response: RPCResponse(id: inviteId, result: wrapper),
            protocolMethod: ChatInviteProtocolMethod()
        )

        let threadSymmetricKey = try kms.performKeyAgreement(selfPublicKey: publicKey, peerPublicKey: inviterPublicKey)
        let threadTopic = threadSymmetricKey.derivedTopic()
        try kms.setSymmetricKey(threadSymmetricKey.sharedKey, for: threadTopic)
        try await networkingInteractor.subscribe(topic: threadTopic)

        logger.debug("Accepting an invite on topic: \(threadTopic)")

        let thread = Thread(
            topic: threadTopic,
            selfAccount: currentAccount,
            peerAccount: invite.inviterAccount
        )

        chatStorage.set(thread: thread, account: currentAccount)
        chatStorage.accept(receivedInvite: invite, account: currentAccount)

        return thread.topic
    }

    func reject(inviteId: Int64) async throws {
        guard let invite = chatStorage.getReceivedInvite(id: inviteId, account: currentAccount)
        else { throw Errors.inviteForIdNotFound }

        let inviteePublicKey = try identityClient.getInviteKey(for: currentAccount)
        let inviterPublicKey = try DIDKey(did: invite.inviterPublicKey)
        let symmAgreementKey = try kms.performKeyAgreement(selfPublicKey: inviteePublicKey, peerPublicKey: inviterPublicKey.hexString)

        let rejectTopic = symmAgreementKey.derivedTopic()
        try kms.setSymmetricKey(symmAgreementKey.sharedKey, for: rejectTopic)

        try await networkingInteractor.respondError(
            topic: rejectTopic,
            requestId: RPCID(inviteId),
            protocolMethod: ChatInviteProtocolMethod(),
            reason: ChatError.userRejected
        )

        chatStorage.reject(receivedInvite: invite, account: currentAccount)
    }
}

private extension InvitationHandlingService {

    enum Errors: Error {
        case inviteForIdNotFound
    }

    func setUpRequestHandling() {
        networkingInteractor.requestSubscription(on: ChatInviteProtocolMethod())
            .sink { [unowned self] (payload: RequestSubscriptionPayload<InvitePayload.Wrapper>) in
                logger.debug("Did receive an invite")

                guard let (invite, claims) = try? InvitePayload.decode(from: payload.request)
                else { fatalError() /* TODO: Handle error */ }

                Task(priority: .high) {
                    let inviterAccount = try await identityClient.resolveIdentity(iss: claims.iss)
                    // TODO: Should we cache it?
                    let inviteePublicKey = try await identityClient.resolveInvite(account: inviterAccount)
                    let inviterPublicKey = invite.inviterPublicKey.did(prefix: false, variant: .X25519)

                    let invite = ReceivedInvite(
                        id: payload.id.integer,
                        message: invite.message,
                        inviterAccount: inviterAccount,
                        inviteeAccount: invite.inviteeAccount,
                        inviterPublicKey: inviterPublicKey,
                        inviteePublicKey: inviteePublicKey,
                        timestamp: payload.publishedAt.millisecondsSince1970
                    )
                    chatStorage.set(receivedInvite: invite, account: invite.inviteeAccount)
                }
            }.store(in: &publishers)
    }
}
