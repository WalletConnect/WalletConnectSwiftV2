import Foundation

actor WalletRespondService {
    enum Errors: Error {
        case recordForIdNotFound
        case malformedAuthRequestParams
    }
    private let networkingInteractor: NetworkInteracting
    private let kms: KeyManagementService
    private let rpcHistory: RPCHistory
    private let verifyContextStore: CodableStore<VerifyContext>
    private let logger: ConsoleLogging
    private let walletErrorResponder: Auth_WalletErrorResponder
    private let pairingRegisterer: PairingRegisterer

    init(
        networkingInteractor: NetworkInteracting,
        logger: ConsoleLogging,
        kms: KeyManagementService,
        rpcHistory: RPCHistory,
        verifyContextStore: CodableStore<VerifyContext>,
        walletErrorResponder: Auth_WalletErrorResponder,
        pairingRegisterer: PairingRegisterer
    ) {
        self.networkingInteractor = networkingInteractor
        self.logger = logger
        self.kms = kms
        self.rpcHistory = rpcHistory
        self.verifyContextStore = verifyContextStore
        self.walletErrorResponder = walletErrorResponder
        self.pairingRegisterer = pairingRegisterer
    }

    func respond(requestId: RPCID, signature: CacaoSignature, account: Account) async throws {
        let authRequestParams = try getAuthRequestParams(requestId: requestId)
        let (topic, keys) = try generateAgreementKeys(requestParams: authRequestParams)

        try kms.setAgreementSecret(keys, topic: topic)

        let header = CacaoHeader(t: "eip4361")
        let payload = try authRequestParams.payloadParams.cacaoPayload(address: account.address)
        let responseParams = AuthResponseParams(h: header, p: payload, s: signature)

        let response = RPCResponse(id: requestId, result: responseParams)
        try await networkingInteractor.respond(topic: topic, response: response, protocolMethod: AuthRequestProtocolMethod(), envelopeType: .type1(pubKey: keys.publicKey.rawRepresentation))
        
        pairingRegisterer.activate(
            pairingTopic: topic,
            peerMetadata: authRequestParams.requester.metadata
        )
        
        verifyContextStore.delete(forKey: requestId.string)
    }

    func respondError(requestId: RPCID) async throws {
        try await walletErrorResponder.respondError(AuthErrors.userRejeted, requestId: requestId)
        verifyContextStore.delete(forKey: requestId.string)
    }

    private func getAuthRequestParams(requestId: RPCID) throws -> Auth_RequestParams {
        guard let request = rpcHistory.get(recordId: requestId)?.request
        else { throw Errors.recordForIdNotFound }

        guard let authRequestParams = try request.params?.get(Auth_RequestParams.self)
        else { throw Errors.malformedAuthRequestParams }

        return authRequestParams
    }

    private func generateAgreementKeys(requestParams: Auth_RequestParams) throws -> (topic: String, keys: AgreementKeys) {
        let peerPubKey = try AgreementPublicKey(hex: requestParams.requester.publicKey)
        let topic = peerPubKey.rawRepresentation.sha256().toHexString()
        let selfPubKey = try kms.createX25519KeyPair()
        let keys = try kms.performKeyAgreement(selfPublicKey: selfPubKey, peerPublicKey: peerPubKey.hexRepresentation)
        return (topic, keys)
    }
}
