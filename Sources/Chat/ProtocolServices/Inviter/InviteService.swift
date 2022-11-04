import Foundation
import Combine

class InviteService {
    private var publishers = [AnyCancellable]()
    private let networkingInteractor: NetworkInteracting
    private let logger: ConsoleLogging
    private let kms: KeyManagementService
    private let threadStore: Database<Thread>
    private let rpcHistory: RPCHistory
    private let registry: Registry

    var onNewThread: ((Thread) -> Void)?
    var onInvite: ((Invite) -> Void)?

    init(
        networkingInteractor: NetworkInteracting,
        kms: KeyManagementService,
        threadStore: Database<Thread>,
        rpcHistory: RPCHistory,
        logger: ConsoleLogging,
        registry: Registry
    ) {
        self.kms = kms
        self.networkingInteractor = networkingInteractor
        self.logger = logger
        self.threadStore = threadStore
        self.rpcHistory = rpcHistory
        self.registry = registry
        setUpResponseHandling()
    }

    var peerAccount: Account!

    func invite(peerAccount: Account, openingMessage: String, account: Account) async throws {
        // TODO ad storage
        let protocolMethod = ChatInviteProtocolMethod()
        self.peerAccount = peerAccount
        let selfPubKeyY = try kms.createX25519KeyPair()
        let invite = Invite(message: openingMessage, account: account, publicKey: selfPubKeyY.hexRepresentation)
        let peerPubKey = try await registry.resolve(account: peerAccount)
        let symKeyI = try kms.performKeyAgreement(selfPublicKey: selfPubKeyY, peerPublicKey: peerPubKey)
        let inviteTopic = try AgreementPublicKey(hex: peerPubKey).rawRepresentation.sha256().toHexString()

        // overrides on invite toipic
        try kms.setSymmetricKey(symKeyI.sharedKey, for: inviteTopic)

        let request = RPCRequest(method: protocolMethod.method, params: invite)

        // 2. Proposer subscribes to topic R which is the hash of the derived symKey
        let responseTopic = symKeyI.derivedTopic()

        try kms.setSymmetricKey(symKeyI.sharedKey, for: responseTopic)

        try await networkingInteractor.subscribe(topic: responseTopic)
        try await networkingInteractor.request(request, topic: inviteTopic, protocolMethod: protocolMethod, envelopeType: .type1(pubKey: selfPubKeyY.rawRepresentation))

        logger.debug("invite sent on topic: \(inviteTopic)")
    }

    private func setUpResponseHandling() {
        networkingInteractor.responseSubscription(on: ChatInviteProtocolMethod())
            .sink { [unowned self] (payload: ResponseSubscriptionPayload<Invite, InviteResponse>) in
                logger.debug("Invite has been accepted")

                Task(priority: .background) {
                    try await createThread(
                        selfPubKeyHex: payload.request.publicKey,
                        peerPubKey: payload.response.publicKey,
                        account: payload.request.account,
                        peerAccount: peerAccount
                    )
                }
            }.store(in: &publishers)
    }

    private func createThread(selfPubKeyHex: String, peerPubKey: String, account: Account, peerAccount: Account) async throws {
        let selfPubKey = try AgreementPublicKey(hex: selfPubKeyHex)
        let agreementKeys = try kms.performKeyAgreement(selfPublicKey: selfPubKey, peerPublicKey: peerPubKey)
        let threadTopic = agreementKeys.derivedTopic()
        try kms.setSymmetricKey(agreementKeys.sharedKey, for: threadTopic)
        try await networkingInteractor.subscribe(topic: threadTopic)
        let thread = Thread(topic: threadTopic, selfAccount: account, peerAccount: peerAccount)
        await threadStore.add(thread)
        onNewThread?(thread)
        // TODO - remove symKeyI
    }
}
