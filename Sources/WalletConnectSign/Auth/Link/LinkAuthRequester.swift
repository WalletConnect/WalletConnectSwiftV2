
import Foundation

actor LinkAuthRequester {
    enum Errors: Error {
        case invalidChain
    }
    private let appMetadata: AppMetadata
    private let kms: KeyManagementService
    private let logger: ConsoleLogging
    private let iatProvader: IATProvider
    private let authResponseTopicRecordsStore: CodableStore<AuthResponseTopicRecord>

    init(kms: KeyManagementService,
         appMetadata: AppMetadata,
         logger: ConsoleLogging,
         iatProvader: IATProvider,
         authResponseTopicRecordsStore: CodableStore<AuthResponseTopicRecord>) {
        self.kms = kms
        self.appMetadata = appMetadata
        self.logger = logger
        self.iatProvader = iatProvader
        self.authResponseTopicRecordsStore = authResponseTopicRecordsStore
    }

    func request(params: AuthRequestParams, walletUniversalLink: String) async throws {


        var params = params
        let pubKey = try kms.createX25519KeyPair()
        let responseTopic = pubKey.rawRepresentation.sha256().toHexString()
        let protocolMethod = SessionAuthenticatedProtocolMethod(ttl: params.ttl)
        guard let chainNamespace = Blockchain(params.chains.first!)?.namespace,
              chainNamespace == "eip155"
        else {
            throw Errors.invalidChain
        }
        if let methods = params.methods,
           !methods.isEmpty {
            let namespaceRecap = try createRecapUrn(methods: methods)
            params.addResource(resource: namespaceRecap)
        }
        let requester = Participant(publicKey: pubKey.hexRepresentation, metadata: appMetadata)
        let payload = AuthPayload(requestParams: params, iat: iatProvader.iat)



        let sessionAuthenticateRequestParams = SessionAuthenticateRequestParams(requester: requester, authPayload: payload, ttl: params.ttl)
        let authResponseTopicRecord = AuthResponseTopicRecord(topic: responseTopic, unixTimestamp: sessionAuthenticateRequestParams.expiryTimestamp)
        authResponseTopicRecordsStore.set(authResponseTopicRecord, forKey: responseTopic)
        let request = RPCRequest(method: protocolMethod.method, params: sessionAuthenticateRequestParams)
        try kms.setPublicKey(publicKey: pubKey, for: responseTopic)




        logger.debug("LinkAuthRequester: sending request")

    }

    private func createRecapUrn(methods: [String]) throws -> String {
        try AuthenticatedSessionRecapUrnFactory.createNamespaceRecap(methods: methods)
    }
}

#if os(iOS)
import UIKit
class LinkTransportInteractor {
    private let serializer: Serializing
    private let logger: ConsoleLogging

    init(serializer: Serializing, logger: ConsoleLogging) {
        self.serializer = serializer
        self.logger = logger
    }

    func request(request: RPCRequest, walletUniversalLink: String) async throws {

        let envelope = try serializer.serializeEnvelopeType2(encodable: request)

        guard var components = URLComponents(string: walletUniversalLink) else { throw URLError(.badURL) }

        components.queryItems = [URLQueryItem(name: "wc_envelope", value: envelope)]

        guard let finalURL = components.url else { throw URLError(.badURL) }

        await UIApplication.shared.open(finalURL)
    }
}
#endif

actor EnvelopeHandler {
    private let serializer: Serializing
    private let logger: ConsoleLogging

    init(serializer: Serializing, logger: ConsoleLogging) {
        self.serializer = serializer
        self.logger = logger
    }

    func handleEnvelope(_ envelope: String) {
        serializer.tryDeserialize(topic: <#T##String#>, encodedEnvelope: <#T##String#>)
    }
}
