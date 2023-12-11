import Foundation

actor IdentityService {

    private let keyserverURL: URL
    private let kms: KeyManagementServiceProtocol
    private let storage: IdentityStorage
    private let networkService: IdentityNetworking
    private let iatProvader: IATProvider
    private let messageFormatter: SIWECacaoFormatting

    init(
        keyserverURL: URL,
        kms: KeyManagementServiceProtocol,
        storage: IdentityStorage,
        networkService: IdentityNetworking,
        iatProvader: IATProvider,
        messageFormatter: SIWECacaoFormatting
    ) {
        self.keyserverURL = keyserverURL
        self.kms = kms
        self.storage = storage
        self.networkService = networkService
        self.iatProvader = iatProvader
        self.messageFormatter = messageFormatter
    }

    func prepareRegistration(account: Account,
        domain: String,
        statement: String,
        resources: [String]) throws -> IdentityRegistrationParams {

        let identityKey = SigningPrivateKey()

        let payload = CacaoPayload(
            iss: account.did,
            domain: domain,
            aud: identityKey.publicKey.did,
            version: getVersion(),
            nonce: getNonce(),
            iat: iatProvader.iat,
            nbf: nil, exp: nil,
            statement: statement,
            requestId: nil,
            resources: resources
        )

        let message = try messageFormatter.formatMessage(from: payload)

        return IdentityRegistrationParams(message: message, payload: payload, privateIdentityKey: identityKey)
    }

    // TODO: Verifications
    func registerIdentity(params: IdentityRegistrationParams, signature: CacaoSignature) async throws -> String {
        let account = try params.account

        if let identityKey = try? storage.getIdentityKey(for: account) {
            return identityKey.publicKey.hexRepresentation
        }

        let cacaoHeader = CacaoHeader(t: "eip4361")
        let cacao = Cacao(h: cacaoHeader, p: params.payload, s: signature)

        try await networkService.registerIdentity(cacao: cacao)
        try storage.saveIdentityKey(params.privateIdentityKey, for: account)

        return params.privateIdentityKey.publicKey.hexRepresentation
    }

    func registerInvite(account: Account) async throws -> AgreementPublicKey {

        if let inviteKey = try? storage.getInviteKey(for: account) {
            return inviteKey
        }

        let inviteKey = try kms.createX25519KeyPair()
        let invitePublicKey = DIDKey(rawData: inviteKey.rawRepresentation)
        let idAuth = try makeIDAuth(account: account, issuer: invitePublicKey, claims: RegisterInviteClaims.self)
        try await networkService.registerInvite(idAuth: idAuth)

        return try storage.saveInviteKey(inviteKey, for: account)
    }

    func unregister(account: Account) async throws {
        let identityKey = try storage.getIdentityKey(for: account)
        let identityPublicKey = DIDKey(rawData: identityKey.publicKey.rawRepresentation)
        let idAuth = try makeIDAuth(account: account, issuer: identityPublicKey, claims: UnregisterIdentityClaims.self)
        try await networkService.removeIdentity(idAuth: idAuth)
        try storage.removeIdentityKey(for: account)
    }

    func goPrivate(account: Account) async throws -> AgreementPublicKey {
        let inviteKey = try storage.getInviteKey(for: account)
        let invitePublicKey = DIDKey(rawData: inviteKey.rawRepresentation)
        let idAuth = try makeIDAuth(account: account, issuer: invitePublicKey, claims: UnregisterInviteClaims.self)
        try await networkService.removeInvite(idAuth: idAuth)
        try storage.removeInviteKey(for: account)

        return inviteKey
    }

    func resolveIdentity(iss: String) async throws -> Account {
        let did = try DIDKey(did: iss).multibase(variant: .ED25519)
        let cacao = try await networkService.resolveIdentity(publicKey: did)
        return try Account(DIDPKHString: cacao.p.iss)
    }

    func resolveInvite(account: Account) async throws -> String {
        return try await networkService.resolveInvite(account: account.absoluteString)
    }
}

private extension IdentityService {

    func makeIDAuth<Claims: IDAuthClaims>(account: Account, issuer: DIDKey, claims: Claims.Type) throws -> String {
        let identityKey = try storage.getIdentityKey(for: account)

        let payload = IDAuthPayload<Claims>(
            keyserver: keyserverURL,
            account: account,
            invitePublicKey: issuer
        )

        return try payload.signAndCreateWrapper(keyPair: identityKey).jwtString
    }

    private func getNonce() -> String {
        return Data.randomBytes(count: 32).toHexString()
    }

    private func getVersion() -> String {
        return "1"
    }
}
