import Foundation
import Combine

class InviteService {

    private var publishers = [AnyCancellable]()
    private let keyserverURL: URL
    private let networkingInteractor: NetworkInteracting
    private let identityClient: IdentityClient
    private let accountService: AccountService
    private let logger: ConsoleLogging
    private let kms: KeyManagementService
    private let chatStorage: ChatStorage

    init(
        keyserverURL: URL,
        networkingInteractor: NetworkInteracting,
        identityClient: IdentityClient,
        accountService: AccountService,
        kms: KeyManagementService,
        chatStorage: ChatStorage,
        logger: ConsoleLogging
    ) {
        self.kms = kms
        self.keyserverURL = keyserverURL
        self.networkingInteractor = networkingInteractor
        self.identityClient = identityClient
        self.accountService = accountService
        self.logger = logger
        self.chatStorage = chatStorage
        setUpResponseHandling()
    }

    @discardableResult
    func invite(invite: Invite) async throws -> Int64 {
        // TODO ad storage
        let protocolMethod = ChatInviteProtocolMethod()
        let selfPubKeyY = try kms.createX25519KeyPair()
        let inviteePublicKey = try DIDKey(did: invite.inviteePublicKey)
        let symKeyI = try kms.performKeyAgreement(selfPublicKey: selfPubKeyY, peerPublicKey: inviteePublicKey.hexString)
        let inviteTopic = try AgreementPublicKey(hex: inviteePublicKey.hexString).rawRepresentation.sha256().toHexString()

        // overrides on invite toipic
        try kms.setSymmetricKey(symKeyI.sharedKey, for: inviteTopic)

        let payload = InvitePayload(
            keyserver: keyserverURL,
            message: invite.message,
            inviteeAccount: invite.inviteeAccount,
            inviterPublicKey: DIDKey(rawData: selfPubKeyY.rawRepresentation)
        )
        let wrapper = try identityClient.signAndCreateWrapper(
            payload: payload,
            account: accountService.currentAccount
        )
        let inviteId = RPCID()
        let request = RPCRequest(method: protocolMethod.method, params: wrapper, rpcid: inviteId)

        // 2. Proposer subscribes to topic R which is the hash of the derived symKey
        let responseTopic = symKeyI.derivedTopic()

        try kms.setSymmetricKey(symKeyI.sharedKey, for: responseTopic)

        try await networkingInteractor.subscribe(topic: responseTopic)
        try await networkingInteractor.request(request, topic: inviteTopic, protocolMethod: protocolMethod, envelopeType: .type1(pubKey: selfPubKeyY.rawRepresentation))

        let sentInvite = SentInvite(
            id: inviteId.integer,
            message: invite.message,
            inviterAccount: invite.inviterAccount,
            inviteeAccount: invite.inviteeAccount,
            timestamp: Date().millisecondsSince1970
        )

        chatStorage.set(sentInvite: sentInvite, account: invite.inviterAccount)

        logger.debug("invite sent on topic: \(inviteTopic)")

        return inviteId.integer
    }
}

private extension InviteService {

    func setUpResponseHandling() {
        networkingInteractor.responseSubscription(on: ChatInviteProtocolMethod())
            .sink { [unowned self] (payload: ResponseSubscriptionPayload<InvitePayload.Wrapper, AcceptPayload.Wrapper>) in
                logger.debug("Invite has been accepted")

                guard
                    let (invite, _) = try? InvitePayload.decode(from: payload.request),
                    let (accept, _) = try? AcceptPayload.decode(from: payload.response)
                else { fatalError() /* TODO: Handle error */ }

                Task(priority: .high) {
                    try await createThread(
                        sentInviteId: payload.id.integer,
                        selfPubKeyHex: invite.inviterPublicKey.hexString,
                        peerPubKey: accept.inviteePublicKey,
                        account: accept.inviterAccount,
                        peerAccount: invite.inviteeAccount
                    )
                }
            }.store(in: &publishers)
    }

    func createThread(sentInviteId: Int64, selfPubKeyHex: String, peerPubKey: DIDKey, account: Account, peerAccount: Account) async throws {
        let selfPubKey = try AgreementPublicKey(hex: selfPubKeyHex)
        let agreementKeys = try kms.performKeyAgreement(selfPublicKey: selfPubKey, peerPublicKey: peerPubKey.hexString)
        let threadTopic = agreementKeys.derivedTopic()
        try kms.setSymmetricKey(agreementKeys.sharedKey, for: threadTopic)

        try await networkingInteractor.subscribe(topic: threadTopic)

        let thread = Thread(
            topic: threadTopic,
            selfAccount: account,
            peerAccount: peerAccount
        )

        chatStorage.set(thread: thread, account: account)

        // TODO: Implement reject for sentInvite
        chatStorage.accept(sentInviteId: sentInviteId, account: account, topic: threadTopic)

        // TODO - remove symKeyI
    }
}
