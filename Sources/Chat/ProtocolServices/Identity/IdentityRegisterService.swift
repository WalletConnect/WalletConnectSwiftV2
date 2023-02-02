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

    func register(account: Account, isPrivate: Bool, onSign: (String) -> CacaoSignature) async throws -> String {
        if let identityKey = identityStorage.getIdentityKey(for: account) {
            return identityKey.publicKey.hexRepresentation
        }

        let identityKey = IdentityKey()
        let identityPublicKey = identityKey.publicKey
        let identityKeyDID = ED25519DIDKeyFactory().make(
            pubKey: identityPublicKey.rawRepresentation, prefix: true
        )
        let cacaoHeader = CacaoHeader(t: "eip4361")
        let cacaoPayload = makeCacaoPayload(identityKeyDID: identityKeyDID, account: account)
        let cacaoSignature = onSign(try messageFormatter.formatMessage(from: cacaoPayload))

        let cacao = Cacao(h: cacaoHeader, p: cacaoPayload, s: cacaoSignature)
        try await identityNetworkService.registerIdentity(cacao: cacao)

        // TODO: Handle private mode

        try identityStorage.saveIdentityKey(identityKey, for: account)
        return identityPublicKey.hexRepresentation
    }
}

private extension IdentityRegisterService {

    func makeCacaoPayload(identityKeyDID: String, account: Account) -> CacaoPayload {
        return CacaoPayload(
            iss: DIDPKH(account: account).iss,
            domain: keyserverURL.host!,
            aud: keyserverURL.absoluteString,
            version: "1",
            nonce: Data.randomBytes(count: 32).toHexString(),
            iat: iatProvader.iat,
            nbf: nil, exp: nil, statement: nil, requestId: nil,
            resources: [identityKeyDID]
        )
    }
}
