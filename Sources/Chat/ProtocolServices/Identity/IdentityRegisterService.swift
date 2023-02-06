import Foundation

actor IdentityRegisterService {

    private let keyserverURL: URL
    private let identityStorage: IdentityStorage
    private let identityNetworkService: IdentityNetworkService
    private let iatProvader: IATProvider
    private let messageFormatter: SIWECacaoFormatting

    init(
        keyserverURL: URL,
        identityStorage: IdentityStorage,
        identityNetworkService: IdentityNetworkService,
        iatProvader: IATProvider,
        messageFormatter: SIWECacaoFormatting
    ) {
        self.keyserverURL = keyserverURL
        self.identityStorage = identityStorage
        self.identityNetworkService = identityNetworkService
        self.iatProvader = iatProvader
        self.messageFormatter = messageFormatter
    }

    func registerIdentity(account: Account,
        isPrivate: Bool,
        onSign: (String) -> CacaoSignature
    ) async throws -> String {

        if let identityKey = identityStorage.getIdentityKey(for: account) {
            return identityKey.publicKey.hexRepresentation
        }

        let identityKey = IdentityKey()
        let cacao = try makeCacao(DIDKey: identityKey.DIDKey, account: account, onSign: onSign)
        try await identityNetworkService.registerIdentity(cacao: cacao)

        // TODO: Handle private mode

        try identityStorage.saveIdentityKey(identityKey, for: account)
        return identityKey.publicKey.hexRepresentation
    }

    func registerInvite(account: Account,
        isPrivate: Bool,
        onSign: (String) -> CacaoSignature
    ) async throws -> String {

        if let inviteKey = identityStorage.getInviteKey(for: account) {
            return inviteKey.publicKey.hexRepresentation
        }

        let inviteKey = IdentityKey()
        let idAuth = try makeIDAuth(account: account, inviteKey: inviteKey)
        try await identityNetworkService.registerInvite(idAuth: idAuth)

        // TODO: Handle private mode

        try identityStorage.saveInviteKey(inviteKey, for: account)
        return inviteKey.publicKey.hexRepresentation
    }

    func resolveIdentity(publicKey: String) async throws -> Cacao {
        let data = Data(hex: publicKey)
        let did = ED25519DIDKeyFactory().make(pubKey: data, prefix: false)
        return try await identityNetworkService.resolveIdentity(publicKey: did)
    }

    func resolveInvite(account: Account) async throws -> String {
        return try await identityNetworkService.resolveInvite(account: account.absoluteString)
    }
}

private extension IdentityRegisterService {

    enum Errors: Error {
        case identityKeyNotFound
    }

    func makeCacao(
        DIDKey: String,
        account: Account,
        onSign: (String) -> CacaoSignature
    ) throws -> Cacao {
        let cacaoHeader = CacaoHeader(t: "eip4361")
        let cacaoPayload = CacaoPayload(
            iss: account.iss,
            domain: keyserverURL.host!,
            aud: getAudience(),
            version: getVersion(),
            nonce: getNonce(),
            iat: iatProvader.iat,
            nbf: nil, exp: nil, statement: nil, requestId: nil,
            resources: [DIDKey]
        )
        let cacaoSignature = onSign(try messageFormatter.formatMessage(from: cacaoPayload))
        return Cacao(h: cacaoHeader, p: cacaoPayload, s: cacaoSignature)
    }

    func makeIDAuth(account: Account, inviteKey: IdentityKey) throws -> String {
        return try JWTFactory().createAndSignJWT(
            keyPair: inviteKey,
            aud: getAudience(),
            exp: getExpiry(),
            pkh: account.iss
        )
    }

    private func getNonce() -> String {
        return Data.randomBytes(count: 32).toHexString()
    }

    private func getVersion() -> String {
        return "1"
    }

    private func getExpiry() -> Int {
        var components = DateComponents()
        components.setValue(1, for: .hour)
        let date = Calendar.current.date(byAdding: components, to: Date())!
        return Int(date.timeIntervalSince1970)
    }

    private func getAudience() -> String {
        return keyserverURL.absoluteString
    }
}
