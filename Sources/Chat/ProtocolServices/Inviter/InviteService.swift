import Foundation
import Combine

class InviteService {
    private var publishers = [AnyCancellable]()
    private let keyserverURL: URL
    private let networkingInteractor: NetworkInteracting
    private let identityStorage: IdentityStorage
    private let accountService: AccountService
    private let logger: ConsoleLogging
    private let kms: KeyManagementService
    private let chatStorage: ChatStorage
    private let registryService: RegistryService

    var onNewThread: ((Thread) -> Void)?
    var onInvite: ((Invite) -> Void)?

    init(
        keyserverURL: URL,
        networkingInteractor: NetworkInteracting,
        identityStorage: IdentityStorage,
        accountService: AccountService,
        kms: KeyManagementService,
        chatStorage: ChatStorage,
        logger: ConsoleLogging,
        registryService: RegistryService
    ) {
        self.kms = kms
        self.keyserverURL = keyserverURL
        self.networkingInteractor = networkingInteractor
        self.identityStorage = identityStorage
        self.accountService = accountService
        self.logger = logger
        self.chatStorage = chatStorage
        self.registryService = registryService
        setUpResponseHandling()
    }

    func invite(peerAccount: Account, openingMessage: String) async throws {
        // TODO ad storage
        let protocolMethod = ChatInviteProtocolMethod()
        let selfPubKeyY = try kms.createX25519KeyPair()
        let peerPubKey = try await registryService.resolve(account: peerAccount)
        let symKeyI = try kms.performKeyAgreement(selfPublicKey: selfPubKeyY, peerPublicKey: peerPubKey)
        let inviteTopic = try AgreementPublicKey(hex: peerPubKey).rawRepresentation.sha256().toHexString()

        // overrides on invite toipic
        try kms.setSymmetricKey(symKeyI.sharedKey, for: inviteTopic)

        let authID = try makeInviteJWT(message: openingMessage, publicKey: DIDKey(rawData: selfPubKeyY.rawRepresentation))
        let payload = InvitePayload(inviteAuth: authID)
        let request = RPCRequest(method: protocolMethod.method, params: payload)

        // 2. Proposer subscribes to topic R which is the hash of the derived symKey
        let responseTopic = symKeyI.derivedTopic()

        try kms.setSymmetricKey(symKeyI.sharedKey, for: responseTopic)

        try await networkingInteractor.subscribe(topic: responseTopic)
        try await networkingInteractor.request(request, topic: inviteTopic, protocolMethod: protocolMethod, envelopeType: .type1(pubKey: selfPubKeyY.rawRepresentation))

        logger.debug("invite sent on topic: \(inviteTopic)")
    }
}

private extension InviteService {

    enum Errors: Error {
        case identityKeyNotFound
    }

    func setUpResponseHandling() {
        networkingInteractor.responseSubscription(on: ChatInviteProtocolMethod())
            .sink { [unowned self] (payload: ResponseSubscriptionPayload<InvitePayload, AcceptPayload>) in
                logger.debug("Invite has been accepted")

                guard
                    let decodedRequest = try? payload.request.decode(),
                    let decodedResponse = try? payload.response.decode()
                else { fatalError() /* TODO: Handle error */ }

                Task(priority: .high) {
                    try await createThread(
                        selfPubKeyHex: decodedRequest.publicKey,
                        peerPubKey: decodedResponse.publicKey,
                        account: decodedRequest.account,
                        peerAccount: decodedResponse.account
                    )
                }
            }.store(in: &publishers)
    }

    func createThread(selfPubKeyHex: String, peerPubKey: String, account: Account, peerAccount: Account) async throws {
        let selfPubKey = try AgreementPublicKey(hex: selfPubKeyHex)
        let agreementKeys = try kms.performKeyAgreement(selfPublicKey: selfPubKey, peerPublicKey: peerPubKey)
        let threadTopic = agreementKeys.derivedTopic()
        try kms.setSymmetricKey(agreementKeys.sharedKey, for: threadTopic)

        try await networkingInteractor.subscribe(topic: threadTopic)

        let thread = Thread(
            topic: threadTopic,
            selfAccount: account,
            peerAccount: peerAccount
        )

        chatStorage.set(thread: thread, account: accountService.currentAccount)

        onNewThread?(thread)
        // TODO - remove symKeyI
    }

    func makeInviteJWT(message: String, publicKey: DIDKey) throws -> String {
        guard let identityKey = identityStorage.getIdentityKey(for: accountService.currentAccount)
        else { throw Errors.identityKeyNotFound }
        return try JWTFactory(keyPair: identityKey).createChatInviteProposalJWT(
            ksu: keyserverURL.absoluteString,
            aud: accountService.currentAccount.did,
            sub: message,
            pke: publicKey.did(prefix: true)
        )
    }
}
