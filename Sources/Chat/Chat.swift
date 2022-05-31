
import Foundation
import WalletConnectUtils
import WalletConnectKMS
import WalletConnectRelay
import Combine

class Chat {
    private var publishers = [AnyCancellable]()
    let registry: Registry
    let engine: Engine
    let kms: KeyManagementService
    var onInvite: ((Invite)->())?
    var onNewThread: ((Thread)->())?
    var onConnected: (()->())?

    init(registry: Registry,
         relayClient: RelayClient,
         kms: KeyManagementService,
         logger: ConsoleLogging = ConsoleLogger(loggingLevel: .off)) {
        self.registry = registry
        
        self.kms = kms
        let serialiser = Serializer(kms: kms)
        let networkingInteractor = NetworkingInteractor(relayClient: relayClient, serializer: serialiser)
        self.engine = Engine(registry: registry, networkingInteractor: networkingInteractor, kms: kms, logger: logger)
        relayClient.socketConnectionStatusPublisher.sink { [unowned self] status in
            if status == .connected {
                onConnected?()
            }
        }.store(in: &publishers)
        engine.onInvite = { [unowned self] invite in
            onInvite?(invite)
        }
        engine.onNewThread = { [unowned self] `thread` in
            onNewThread?(`thread`)
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

