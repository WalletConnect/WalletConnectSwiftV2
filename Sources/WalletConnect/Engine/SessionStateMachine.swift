//
//import Foundation
//import WalletConnectUtils
//import WalletConnectKMS
//
//final class SessionStateMachine {
//    
//    var onSessionUpdate: ((String, Set<Account>)->())?
//    
//    private let sequencesStore: SessionSequenceStorage
//    private let wcSubscriber: WCSubscribing
//    private let relayer: WalletConnectRelaying
//    private let kms: KeyManagementServiceProtocol
//    private var publishers = [AnyCancellable]()
//    private let logger: ConsoleLogging
//
//    init(relay: WalletConnectRelaying,
//         kms: KeyManagementServiceProtocol,
//         subscriber: WCSubscribing,
//         sequencesStore: SessionSequenceStorage,
//         metadata: AppMetadata,
//         logger: ConsoleLogging,
//         topicGenerator: @escaping () -> String = String.generateTopic) {
//        self.relayer = relay
//        self.kms = kms
//        self.wcSubscriber = subscriber
//        self.sequencesStore = sequencesStore
//        self.logger = logger
//
//        setUpWCRequestHandling()
//        
//        relayer.onResponse = { [weak self] in
//            self?.handleResponse($0)
//        }
//    }
//    
//    
//    func updateAccounts(topic: String, accounts: Set<Account>) throws {
//        guard var session = sequencesStore.getSequence(forTopic: topic) else {
//            throw WalletConnectError.noSessionMatchingTopic(topic)
//        }
//        guard session.acknowledged else {
//            throw WalletConnectError.sessionNotAcknowledged(topic)
//        }
//        guard session.selfIsController else {
//            throw WalletConnectError.unauthorizedNonControllerCall
//        }
//        session.update(accounts)
//        sequencesStore.setSequence(session)
//        relayer.request(.wcSessionUpdate(SessionType.UpdateParams(accounts: accounts)), onTopic: topic)
//    }
//    
//    func updateMethods(topic: String, methods: Set<String>) throws {
//        let permissions = SessionPermissions(permissions: permissions)
//        guard var session = sequencesStore.getSequence(forTopic: topic) else {
//            throw WalletConnectError.noSessionMatchingTopic(topic)
//        }
//        guard session.acknowledged else {
//            throw WalletConnectError.sessionNotAcknowledged(topic)
//        }
//        guard session.selfIsController else {
//            throw WalletConnectError.unauthorizedNonControllerCall
//        }
//        guard validatePermissions(permissions) else {
//            throw WalletConnectError.invalidPermissions
//        }
//        session.upgrade(permissions)
//        let newPermissions = session.permissions
//        sequencesStore.setSequence(session)
//        relayer.request(.wcSessionUpgrade(SessionType.UpgradeParams(permissions: newPermissions)), onTopic: topic)
//    }
//}
