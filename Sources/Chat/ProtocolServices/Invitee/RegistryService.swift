import Foundation

// TODO: RegistryService / register service naming
actor RegistryService {
    private let networkingInteractor: NetworkInteracting
    private let accountService: AccountService
    private let resubscriptionService: ResubscriptionService
    private let registerService: IdentityRegisterService
    private let logger: ConsoleLogging
    private let kms: KeyManagementServiceProtocol

    init(
        registerService: IdentityRegisterService,
        accountService: AccountService,
        resubscriptionService: ResubscriptionService,
        networkingInteractor: NetworkInteracting,
        kms: KeyManagementServiceProtocol,
        logger: ConsoleLogging
    ) {
        self.registerService = registerService
        self.kms = kms
        self.accountService = accountService
        self.resubscriptionService = resubscriptionService
        self.networkingInteractor = networkingInteractor
        self.logger = logger
    }

    func register(account: Account,
        isPrivate: Bool,
        onSign: (String) -> CacaoSignature
    ) async throws -> String {
        let publicKey = try await registerService.registerIdentity(account: account, onSign: onSign)

        guard !isPrivate else { return publicKey }

        try await goPublic(account: account, onSign: onSign)
        return publicKey
    }

    func goPublic(account: Account, onSign: (String) -> CacaoSignature) async throws {
        let pubKey = try await registerService.registerInvite(account: account, onSign: onSign)

        let topic = pubKey.rawRepresentation.sha256().toHexString()
        try kms.setPublicKey(publicKey: pubKey, for: topic)
        try await networkingInteractor.subscribe(topic: topic)

        let oldAccount = accountService.currentAccount
        try await resubscriptionService.unsubscribe(account: oldAccount)
        accountService.setAccount(account)
        try await resubscriptionService.resubscribe(account: account)

        logger.debug("Did register an account: \(account) and is subscribing on topic: \(topic)")
    }

    func resolve(account: Account) async throws -> String {
        return try await registerService.resolveInvite(account: account)
    }
}

struct RegistryRecord: Codable {
    let account: Account
    let pubKey: String
}
