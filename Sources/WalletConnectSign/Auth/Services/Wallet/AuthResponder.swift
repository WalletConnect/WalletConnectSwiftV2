import Foundation
import Combine

actor AuthResponder {
    enum Errors: Error {
        case recordForIdNotFound
        case malformedAuthRequestParams
        case cannotCreateSessionNamespaceFromTheRecap
    }
    private let networkingInteractor: NetworkInteracting
    private let kms: KeyManagementService
    private let rpcHistory: RPCHistory
    private let verifyContextStore: CodableStore<VerifyContext>
    private let logger: ConsoleLogging
    private let walletErrorResponder: WalletErrorResponder
    private let pairingRegisterer: PairingRegisterer
    private let metadata: AppMetadata
    private let sessionStore: WCSessionStorage
    private let sessionSettledPublisherSubject = PassthroughSubject<Session, Never>()
    var sessionSettledPublisher: AnyPublisher<Session, Never> {
        return sessionSettledPublisherSubject.eraseToAnyPublisher()
    }

    init(
        networkingInteractor: NetworkInteracting,
        logger: ConsoleLogging,
        kms: KeyManagementService,
        rpcHistory: RPCHistory,
        verifyContextStore: CodableStore<VerifyContext>,
        walletErrorResponder: WalletErrorResponder,
        pairingRegisterer: PairingRegisterer,
        metadata: AppMetadata,
        sessionStore: WCSessionStorage
    ) {
        self.networkingInteractor = networkingInteractor
        self.logger = logger
        self.kms = kms
        self.rpcHistory = rpcHistory
        self.verifyContextStore = verifyContextStore
        self.walletErrorResponder = walletErrorResponder
        self.pairingRegisterer = pairingRegisterer
        self.metadata = metadata
        self.sessionStore = sessionStore
    }

    func respond(requestId: RPCID, auths: [AuthObject]) async throws {
        let (sessionAuthenticateRequestParams, pairingTopic) = try getsessionAuthenticateRequestParams(requestId: requestId)
        let (sessionTopic, keys) = try generateAgreementKeys(requestParams: sessionAuthenticateRequestParams)


        try kms.setAgreementSecret(keys, topic: sessionTopic)

        let selfParticipant = Participant(publicKey: keys.publicKey.hexRepresentation, metadata: metadata)
        let responseParams = SessionAuthenticateResponseParams(responder: selfParticipant, cacaos: auths)

        let response = RPCResponse(id: requestId, result: responseParams)
        try await networkingInteractor.respond(topic: sessionTopic, response: response, protocolMethod: SessionAuthenticatedProtocolMethod(), envelopeType: .type1(pubKey: keys.publicKey.rawRepresentation))


        let session = try createSession(
            response: responseParams,
            pairingTopic: pairingTopic,
            request: sessionAuthenticateRequestParams,
            sessionTopic: sessionTopic
        )

        pairingRegisterer.activate(
            pairingTopic: pairingTopic,
            peerMetadata: sessionAuthenticateRequestParams.requester.metadata
        )

        verifyContextStore.delete(forKey: requestId.string)
        sessionSettledPublisherSubject.send(session)
    }

    func respondError(requestId: RPCID) async throws {
        try await walletErrorResponder.respondError(AuthError.userRejeted, requestId: requestId)
        verifyContextStore.delete(forKey: requestId.string)
    }

    private func getsessionAuthenticateRequestParams(requestId: RPCID) throws -> (request: SessionAuthenticateRequestParams, topic: String) {
        guard let record = rpcHistory.get(recordId: requestId)
        else { throw Errors.recordForIdNotFound }

        let request = record.request
        guard let authRequestParams = try request.params?.get(SessionAuthenticateRequestParams.self)
        else { throw Errors.malformedAuthRequestParams }

        return (request: authRequestParams, topic: record.topic)
    }

    private func generateAgreementKeys(requestParams: SessionAuthenticateRequestParams) throws -> (topic: String, keys: AgreementKeys) {
        let peerPubKey = try AgreementPublicKey(hex: requestParams.requester.publicKey)
        let topic = peerPubKey.rawRepresentation.sha256().toHexString()
        let selfPubKey = try kms.createX25519KeyPair()
        let keys = try kms.performKeyAgreement(selfPublicKey: selfPubKey, peerPublicKey: peerPubKey.hexRepresentation)
        return (topic, keys)
    }


    private func createSession(
        response: SessionAuthenticateResponseParams,
        pairingTopic: String,
        request: SessionAuthenticateRequestParams,
        sessionTopic: String
    ) throws -> Session {


        let selfParticipant = response.responder
        let peerParticipant = request.requester

        let expiry = Date()
            .addingTimeInterval(TimeInterval(WCSession.defaultTimeToLive))
            .timeIntervalSince1970

        let relay = RelayProtocolOptions(protocol: "irn", data: nil)

        let sessionNamespaces = try buildSessionNamespaces(cacaos: response.cacaos)

        let settleParams = SessionType.SettleParams(
            relay: relay,
            controller: selfParticipant,
            namespaces: sessionNamespaces,
            sessionProperties: nil,
            expiry: Int64(expiry)
        )

        let session = WCSession(
            topic: sessionTopic,
            pairingTopic: pairingTopic,
            timestamp: Date(),
            selfParticipant: selfParticipant,
            peerParticipant: peerParticipant,
            settleParams: settleParams,
            requiredNamespaces: [:],
            acknowledged: true
        )

        sessionStore.setSession(session)
        Task {
            try await networkingInteractor.subscribe(topic: sessionTopic)
        }

        return session.publicRepresentation()
    }

    private func buildSessionNamespaces(cacaos: [Cacao]) throws -> [String: SessionNamespace] {

        guard let cacao = cacaos.first,
              let resources = cacao.p.resources,
              let namespacesUrn = resources.last,
              let decodedRecap = decodeUrnToJson(urn: namespacesUrn),
              let chainsNamespace = try? DIDPKH(did: cacao.p.iss).account.blockchain.namespace else {
            throw Errors.cannotCreateSessionNamespaceFromTheRecap
        }

        let accounts = cacaos.compactMap{ try? DIDPKH(did: $0.p.iss).account }
        
        let accountsSet = Set(accounts)

        let methods = getMethods(from: decodedRecap)

        let sessionNamespace = SessionNamespace(accounts: accountsSet, methods: methods, events: [])
        return [chainsNamespace: sessionNamespace]
    }


    private func decodeUrnToJson(urn: String) -> [String: [String: [String: [String]]]]? {
        // Extract the Base64 encoded JSON part from the URN
        let components = urn.components(separatedBy: ":")
        guard components.count >= 3, let base64EncodedJson = components.last else {
            logger.debug("Invalid URN format")
            return nil
        }

        // Decode the Base64 encoded JSON
        guard let jsonData = Data(base64Encoded: base64EncodedJson) else {
            logger.debug("Failed to decode Base64 string")
            return nil
        }

        // Deserialize the JSON data into the desired dictionary
        do {
            let decodedDictionary = try JSONDecoder().decode([String: [String: [String: [String]]]].self, from: jsonData)
            return decodedDictionary
        } catch {
            logger.debug("Error during JSON decoding: \(error.localizedDescription)")
            return nil
        }
    }

    func getMethods(from recap: [String: [String: [String: [String]]]]) -> Set<String> {
        var requestMethods: [String] = []

        // Iterate through the recap dictionary
        for (_, resources) in recap {
            for (_, requests) in resources {
                for (key, _) in requests {

                // Check if the key starts with "request/"
                    if key.hasPrefix("request/") {
                        // Extract the method name and add it to the array
                        let methodName = String(key.dropFirst("request/".count))
                        requestMethods.append(methodName)
                    }
                }
            }
        }

        return Set(requestMethods)
    }

}

