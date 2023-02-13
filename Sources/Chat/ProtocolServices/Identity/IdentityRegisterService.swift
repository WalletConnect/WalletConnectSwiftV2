import Foundation

actor IdentityRegisterService {

    private let keyserverURL: URL
    private let kms: KeyManagementServiceProtocol
    private let identityStorage: IdentityStorage
    private let identityNetworkService: Registry
    private let iatProvader: IATProvider
    private let messageFormatter: SIWECacaoFormatting

    init(
        keyserverURL: URL,
        kms: KeyManagementServiceProtocol,
        identityStorage: IdentityStorage,
        identityNetworkService: Registry,
        iatProvader: IATProvider,
        messageFormatter: SIWECacaoFormatting
    ) {
        self.keyserverURL = keyserverURL
        self.kms = kms
        self.identityStorage = identityStorage
        self.identityNetworkService = identityNetworkService
        self.iatProvader = iatProvader
        self.messageFormatter = messageFormatter
    }

    func registerIdentity(account: Account,
        onSign: (String) -> CacaoSignature
    ) async throws -> String {

        if let identityKey = identityStorage.getIdentityKey(for: account) {
            return identityKey.publicKey.hexRepresentation
        }

        let identityKey = SigningPrivateKey()
        let cacao = try makeCacao(DIDKey: identityKey.publicKey.did, account: account, onSign: onSign)
        try await identityNetworkService.registerIdentity(cacao: cacao)

        return try identityStorage.saveIdentityKey(identityKey, for: account).publicKey.hexRepresentation
    }

    func registerInvite(account: Account,
        onSign: (String) -> CacaoSignature
    ) async throws -> AgreementPublicKey {

        if let inviteKey = identityStorage.getInviteKey(for: account) {
            return inviteKey
        }

        let inviteKey = try kms.createX25519KeyPair()
        let invitePublicKey = inviteKey.hexRepresentation
        let idAuth = try makeIDAuth(account: account, invitePublicKey: invitePublicKey)
        try await identityNetworkService.registerInvite(idAuth: idAuth)

        return try identityStorage.saveInviteKey(inviteKey, for: account)
    }

    func resolveIdentity(publicKey: String) async throws -> Cacao {
        let data = Data(hex: publicKey)
        let did = DIDKey(rawData: data).did(prefix: false)
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
            iss: account.did,
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

    func makeIDAuth(account: Account, invitePublicKey: String) throws -> String {
        guard let identityKey = identityStorage.getIdentityKey(for: account)
        else { throw Errors.identityKeyNotFound }
        return try JWTFactory(keyPair: identityKey).createChatInviteJWT(
            sub: invitePublicKey,
            aud: getAudience(),
            pkh: account.did
        )
    }

    private func getNonce() -> String {
        return Data.randomBytes(count: 32).toHexString()
    }

    private func getVersion() -> String {
        return "1"
    }

    private func getAudience() -> String {
        return keyserverURL.absoluteString
    }
}
