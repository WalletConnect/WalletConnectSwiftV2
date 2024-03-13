import Foundation

public enum SigningResult {
    case signed(CacaoSignature)
    case rejected
}

public typealias SigningCallback = (String) async -> SigningResult

public final class IdentityClient {
    private let identityService: IdentityService
    private let identityStorage: IdentityStorage
    private let logger: ConsoleLogging

    init(
        identityService: IdentityService,
        identityStorage: IdentityStorage,
        logger: ConsoleLogging
    ) {
        self.identityService = identityService
        self.identityStorage = identityStorage
        self.logger = logger
    }

    public func prepareRegistration(account: Account,
        domain: String,
        statement: String? = nil,
        resources: [String]) async throws -> IdentityRegistrationParams
    {
        let registration = try await identityService.prepareRegistration(account: account, domain: domain, statement: statement, resources: resources)
        logger.debug("Did prepare registration for \(account)")
        return registration
    }

    @discardableResult
    public func register(params: IdentityRegistrationParams, signature: CacaoSignature) async throws -> String {
        let account = try params.account
        let pubKey = try await identityService.registerIdentity(params: params, signature: signature)
        logger.debug("Did register an account: \(account)")
        return pubKey
    }

    public func goPublic(account: Account) async throws -> AgreementPublicKey {
        let inviteKey = try await identityService.registerInvite(account: account)
        logger.debug("Did goPublic an account: \(account)")
        return inviteKey
    }

    public func unregister(account: Account) async throws {
        try await identityService.unregister(account: account)
        logger.debug("Did unregister an account: \(account)")
    }

    public func goPrivate(account: Account) async throws -> AgreementPublicKey {
        let inviteKey = try await identityService.goPrivate(account: account)
        logger.debug("Did goPrivate an account: \(account)")
        return inviteKey
    }

    public func setInviteKey(_ inviteKey: AgreementPublicKey, account: Account) throws {
        try identityStorage.saveInviteKey(inviteKey, for: account)
    }

    public func deleteInviteKey(account: Account) throws {
        try identityStorage.removeInviteKey(for: account)
    }

    public func resolveInvite(account: Account) async throws -> String {
        return try await identityService.resolveInvite(account: account)
    }

    public func resolveIdentity(iss: String) async throws -> Account {
        return try await identityService.resolveIdentity(iss: iss)
    }

    public func signAndCreateWrapper<T: JWTClaimsCodable>(
        payload: T,
        account: Account
    ) throws -> T.Wrapper {
        let identityKey = try identityStorage.getIdentityKey(for: account)
        return try payload.signAndCreateWrapper(keyPair: identityKey)
    }

    public func getInviteKey(for account: Account) throws -> AgreementPublicKey {
        return try identityStorage.getInviteKey(for: account)
    }

    public func isIdentityRegistered(account: Account) -> Bool {
        let key = try? identityStorage.getIdentityKey(for: account)
        return key != nil
    }
}
