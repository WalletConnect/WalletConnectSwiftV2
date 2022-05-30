
import Foundation
import WalletConnectUtils
import WalletConnectKMS
import WalletConnectRelay


protocol MessagingDelegate: AnyObject {
    func didReceiveInvite(_ invite: Invite)
}

class Chat {
    let registry: Registry
    let engine: Engine
    let kms: KeyManagementService
    var onInvite: ((Invite)->())?
    var onNewThread: ((Thread)->())?
    public weak var delegate: MessagingDelegate?

    init(registry: Registry,
         relayClient: RelayClient,
         kms: KeyManagementService) {
        self.registry = registry
        
        self.kms = kms
        let serialiser = Serializer(kms: kms)
        let networkingInteractor = NetworkingInteractor(relayClient: relayClient, serializer: serialiser)
        self.engine = Engine(registry: registry, networkingInteractor: networkingInteractor, kms: kms)
        
        engine.onInvite = { [unowned self] invite in
            delegate?.didReceiveInvite(invite)
            onInvite?(invite)
        }
    }
    
    func register(account: Account) {
        engine.register(account: account)
    }
    
    func invite(account: Account) {
        engine.invite(account: account)
    }
    
    func accept(invite: Invite) {
        engine.accept(invite: invite)
    }
    
    func message(threadTopic: String, message: String) {
        
    }
}

