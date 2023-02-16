import Foundation

actor RegistryService {
    private let networkingInteractor: NetworkInteracting
    private let identityService: IdentityService
    private let logger: ConsoleLogging
    private let kms: KeyManagementServiceProtocol

    init(
        identityService: IdentityService,
        networkingInteractor: NetworkInteracting,
        kms: KeyManagementServiceProtocol,
        logger: ConsoleLogging
    ) {
        self.identityService = identityService
        self.kms = kms
        self.networkingInteractor = networkingInteractor
        self.logger = logger
    }

    func register(account: Account, onSign: (String) -> CacaoSignature) async throws -> String {
        let pubKey = try await identityService.registerIdentity(account: account, onSign: onSign)
        logger.debug("Did register an account: \(account)")
        return pubKey
    }

    func goPublic(account: Account, onSign: (String) -> CacaoSignature) async throws {
        let inviteKey = try await identityService.registerInvite(account: account, onSign: onSign)
        try await subscribeForInvites(inviteKey: inviteKey)
        logger.debug("Did goPublic an account: \(account)")
    }

    func unregister(account: Account, onSign: (String) -> CacaoSignature) async throws {
        try await identityService.unregister(account: account, onSign: onSign)
        logger.debug("Did unregister an account: \(account)")
    }

    func goPrivate(account: Account) async throws {
        let inviteKey = try await identityService.goPrivate(account: account)
        unsubscribeFromInvites(inviteKey: inviteKey)
        logger.debug("Did goPrivate an account: \(account)")
    }

    func resolve(account: Account) async throws -> String {
        return try await identityService.resolveInvite(account: account)
    }
}

private extension RegistryService {

    func subscribeForInvites(inviteKey: AgreementPublicKey) async throws {
        let topic = inviteKey.rawRepresentation.sha256().toHexString()
        try kms.setPublicKey(publicKey: inviteKey, for: topic)
        try await networkingInteractor.subscribe(topic: topic)
    }

    func unsubscribeFromInvites(inviteKey: AgreementPublicKey) {
        let topic = inviteKey.rawRepresentation.sha256().toHexString()
        kms.deletePublicKey(for: topic)
        networkingInteractor.unsubscribe(topic: topic)
    }
}
