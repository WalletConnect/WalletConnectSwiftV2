import Foundation

actor RegistryService {
    private let networkingInteractor: NetworkInteracting
    private let accountService: AccountService
    private let resubscriptionService: ResubscriptionService
    private let topicToRegistryRecordStore: CodableStore<RegistryRecord>
    private let registry: Registry
    private let logger: ConsoleLogging
    private let kms: KeyManagementServiceProtocol

    init(registry: Registry,
         accountService: AccountService,
         resubscriptionService: ResubscriptionService,
         networkingInteractor: NetworkInteracting,
         kms: KeyManagementServiceProtocol,
         logger: ConsoleLogging,
         topicToRegistryRecordStore: CodableStore<RegistryRecord>) {
        self.registry = registry
        self.kms = kms
        self.accountService = accountService
        self.resubscriptionService = resubscriptionService
        self.networkingInteractor = networkingInteractor
        self.logger = logger
        self.topicToRegistryRecordStore = topicToRegistryRecordStore
    }

    func register(account: Account) async throws -> String {
        let pubKey = try kms.createX25519KeyPair()
        let pubKeyHex = pubKey.hexRepresentation
        try await registry.register(account: account, pubKey: pubKeyHex)

        let topic = pubKey.rawRepresentation.sha256().toHexString()
        try kms.setPublicKey(publicKey: pubKey, for: topic)

        let record = RegistryRecord(account: account, pubKey: pubKeyHex)
        topicToRegistryRecordStore.set(record, forKey: topic)

        try await networkingInteractor.subscribe(topic: topic)

        let oldAccount = accountService.currentAccount
        try await resubscriptionService.unsubscribe(account: oldAccount)
        accountService.setAccount(account)
        try await resubscriptionService.resubscribe(account: account)

        logger.debug("Did register an account: \(account) and is subscribing on topic: \(topic)")

        return pubKeyHex
    }
}

struct RegistryRecord: Codable {
    let account: Account
    let pubKey: String
}
