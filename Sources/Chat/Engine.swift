
import Foundation
import WalletConnectKMS
import WalletConnectUtils
import WalletConnectRelay
import Combine

class Engine {
    var onInvite: ((InviteParams)->())?
    var onNewThread: ((Thread)->())?
    let networkingInteractor: NetworkingInteractor
    let inviteStore: CodableStore<(InviteParams)>
    let topicToInvitationPubKeyStore: CodableStore<String>
    let registry: Registry
    let logger: ConsoleLogging
    let kms: KeyManagementService
    let threadsStore: CodableStore<Thread>
    private var publishers = [AnyCancellable]()
    
    init(registry: Registry,
         networkingInteractor: NetworkingInteractor,
         kms: KeyManagementService,
         logger: ConsoleLogging,
         topicToInvitationPubKeyStore: CodableStore<String>,
         inviteStore: CodableStore<InviteParams>,
         threadsStore: CodableStore<Thread>) {
        self.registry = registry
        self.kms = kms
        self.networkingInteractor = networkingInteractor
        self.logger = logger
        self.topicToInvitationPubKeyStore = topicToInvitationPubKeyStore
        self.inviteStore = inviteStore
        self.threadsStore = threadsStore
        setUpRequestHandling()
        setUpResponseHandling()
    }

    func accept(inviteId: String) async throws {
        guard let hexPubKey = try topicToInvitationPubKeyStore.get(key: "todo-topic") else {
            throw ChatError.noPublicKeyForInviteId
        }
        let pubKey = try! AgreementPublicKey(hex: hexPubKey)
        guard let invite = try inviteStore.get(key: inviteId) else {
            throw ChatError.noInviteForId
        }
        logger.debug("accepting an invitation")
        let agreementKeys = try! kms.performKeyAgreement(selfPublicKey: pubKey, peerPublicKey: invite.pubKey)
        let topic = agreementKeys.derivedTopic()
        try await networkingInteractor.subscribe(topic: topic)
        fatalError("not implemented")
    }

    private func handleInvite(_ invite: InviteParams) {
        onInvite?(invite)
        logger.debug("did receive an invite")
        try? inviteStore.set(invite, forKey: invite.id)
//        networkingInteractor.respondSuccess(for: RequestSubscriptionPayload)
    }

    private func setUpRequestHandling() {
        networkingInteractor.requestPublisher.sink { [unowned self] subscriptionPayload in
            switch subscriptionPayload.request.params {
            case .invite(let invite):
                handleInvite(invite)
            case .message(let message):
                print("received message: \(message)")
            }
        }.store(in: &publishers)
    }

    private func setUpResponseHandling() {
        networkingInteractor.responsePublisher.sink { [unowned self] response in
            switch response.requestParams {
            case .message(let message):
                print("received message response: \(message)")
            default:
                return
            }
        }.store(in: &publishers)
    }
}
