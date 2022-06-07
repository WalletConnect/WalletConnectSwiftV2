
import Foundation
import WalletConnectUtils
import WalletConnectKMS

actor RegistryManager {
    let networkingInteractor: NetworkInteracting
    let topicToInvitationPubKeyStore: CodableStore<String>
    let registry: Registry
    let logger: ConsoleLogging
    let kms: KeyManagementServiceProtocol
    
    init(registry: Registry,
         networkingInteractor: NetworkInteracting,
         kms: KeyManagementServiceProtocol,
         logger: ConsoleLogging,
         topicToInvitationPubKeyStore: CodableStore<String>) {
        self.registry = registry
        self.kms = kms
        self.networkingInteractor = networkingInteractor
        self.logger = logger
        self.topicToInvitationPubKeyStore = topicToInvitationPubKeyStore
    }
    
    func register(account: Account) async throws -> String {
        let pubKey = try kms.createX25519KeyPair()
        let pubKeyHex = pubKey.hexRepresentation
        try await registry.register(account: account, pubKey: pubKeyHex)
        let topic = pubKey.rawRepresentation.sha256().toHexString()
        topicToInvitationPubKeyStore.set(pubKeyHex, forKey: topic)
        try await networkingInteractor.subscribe(topic: topic)
        logger.debug("Did register an account: \(account) and is subscribing on topic: \(topic)")
        return pubKeyHex
    }
}
