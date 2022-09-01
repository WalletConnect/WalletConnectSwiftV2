import Foundation
import Combine
import JSONRPC
import WalletConnectKMS
import WalletConnectUtils
import WalletConnectNetworking

class InviteService {
    private var publishers = [AnyCancellable]()
    private let networkingInteractor: NetworkInteracting
    private let logger: ConsoleLogging
    private let kms: KeyManagementService
    private let threadStore: Database<Thread>
    private let rpcHistory: RPCHistory

    var onNewThread: ((Thread) -> Void)?
    var onInvite: ((Invite) -> Void)?

    init(networkingInteractor: NetworkInteracting,
         kms: KeyManagementService,
         threadStore: Database<Thread>,
         rpcHistory: RPCHistory,
         logger: ConsoleLogging) {
        self.kms = kms
        self.networkingInteractor = networkingInteractor
        self.logger = logger
        self.threadStore = threadStore
        self.rpcHistory = rpcHistory
        setUpResponseHandling()
    }

    var peerAccount: Account!

    func invite(peerPubKey: String, peerAccount: Account, openingMessage: String, account: Account) async throws {
        // TODO ad storage
        self.peerAccount = peerAccount
        let selfPubKeyY = try kms.createX25519KeyPair()
        let invite = Invite(message: openingMessage, account: account, publicKey: selfPubKeyY.hexRepresentation)
        let symKeyI = try kms.performKeyAgreement(selfPublicKey: selfPubKeyY, peerPublicKey: peerPubKey)
        let inviteTopic = try AgreementPublicKey(hex: peerPubKey).rawRepresentation.sha256().toHexString()

        // overrides on invite toipic
        try kms.setSymmetricKey(symKeyI.sharedKey, for: inviteTopic)

        let request = RPCRequest(method: Invite.method, params: invite)

        // 2. Proposer subscribes to topic R which is the hash of the derived symKey
        let responseTopic = symKeyI.derivedTopic()

        try kms.setSymmetricKey(symKeyI.sharedKey, for: responseTopic)

        try await networkingInteractor.subscribe(topic: responseTopic)
        try await networkingInteractor.request(request, topic: inviteTopic, tag: Invite.tag, envelopeType: .type1(pubKey: selfPubKeyY.rawRepresentation))

        logger.debug("invite sent on topic: \(inviteTopic)")
    }

    private func setUpResponseHandling() {
        networkingInteractor.responsePublisher
            .sink { [unowned self] payload in
                do {
                    guard
                        let requestId = payload.response.id,
                        let request = rpcHistory.get(recordId: requestId)?.request,
                        let requestParams = request.params, request.method == Invite.method
                    else { return }

                    guard let inviteResponse = try payload.response.result?.get(InviteResponse.self)
                    else { return }

                    let inviteParams = try requestParams.get(Invite.self)

                    logger.debug("Invite has been accepted")

                    Task(priority: .background) {
                        try await createThread(selfPubKeyHex: inviteParams.publicKey, peerPubKey: inviteResponse.publicKey, account: inviteParams.account, peerAccount: peerAccount)
                    }
                } catch {
                    logger.debug("Handling invite response has failed")
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
