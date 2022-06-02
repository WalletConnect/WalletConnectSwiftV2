
import Foundation
import WalletConnectKMS
import WalletConnectUtils
import WalletConnectRelay
import Combine

class Engine {
    var onInvite: ((Invite)->())?
    var onNewThread: ((Thread)->())?
    let networkingInteractor: NetworkingInteractor
    let inviteStore: KeyValueStore<(Invite)>
    let topicToInvitationPubKeyStore: KeyValueStore<String>
    let registry: Registry
    let logger: ConsoleLogging
    let kms: KeyManagementService
    let threadsStore: KeyValueStore<Thread>
    private var publishers = [AnyCancellable]()
    
    init(registry: Registry,
         networkingInteractor: NetworkingInteractor,
         kms: KeyManagementService,
         logger: ConsoleLogging,
         topicToInvitationPubKeyStore: KeyValueStore<String>,
         inviteStore: KeyValueStore<Invite>,
         threadsStore: KeyValueStore<Thread>) {
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
    
    func invite(account: Account) throws {
        let peerPubKeyHex = registry.resolve(account: account)!
        print("resolved pub key: \(peerPubKeyHex)")
        let pubKey = try kms.createX25519KeyPair()
        let invite = Invite(pubKey: pubKey.hexRepresentation, message: "hello")
        let topic = try AgreementPublicKey(hex: peerPubKeyHex).rawRepresentation.sha256().toHexString()
        let request = ChatRequest(method: .invite, params: .invite(invite))
        networkingInteractor.requestUnencrypted(request, topic: topic)
        let agreementKeys = try kms.performKeyAgreement(selfPublicKey: pubKey, peerPublicKey: peerPubKeyHex)
        let threadTopic = agreementKeys.derivedTopic()
        networkingInteractor.subscribe(topic: threadTopic)
        logger.debug("invite sent on topic: \(topic)")
    }
        
    
    func accept(inviteId: String) throws {
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
        networkingInteractor.subscribe(topic: topic)
        fatalError("not implemented")
    }
        
    func register(account: Account) {
        let pubKey = try! kms.createX25519KeyPair()
        let pubKeyHex = pubKey.hexRepresentation
        print("registered pubKey: \(pubKeyHex)")
        registry.register(account: account, pubKey: pubKeyHex)
        let topic = pubKey.rawRepresentation.sha256().toHexString()
        try! topicToInvitationPubKeyStore.set(pubKeyHex, forKey: topic)
        networkingInteractor.subscribe(topic: topic)
        print("did register and is subscribing on topic: \(topic)")
    }
    
    private func handleInvite(_ invite: Invite) {
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
            case .invite(let invite):
                fatalError("not implemented")
            case .message(let message):
                print("received message response: \(message)")
            }
        }.store(in: &publishers)
    }
}
