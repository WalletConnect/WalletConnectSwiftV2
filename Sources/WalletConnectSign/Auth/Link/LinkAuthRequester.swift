
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



import Combine
class EnvelopesDispatcher {
    private let serializer: Serializing
    private let logger: ConsoleLogging

    private let requestPublisherSubject = PassthroughSubject<(topic: String, request: RPCRequest), Never>()
    private let responsePublisherSubject = PassthroughSubject<(topic: String, request: RPCRequest, response: RPCResponse, publishedAt: Date, derivedTopic: String?), Never>()

    public var requestPublisher: AnyPublisher<(topic: String, request: RPCRequest), Never> {
        requestPublisherSubject.eraseToAnyPublisher()
    }

    private var responsePublisher: AnyPublisher<(topic: String, request: RPCRequest, response: RPCResponse, publishedAt: Date, derivedTopic: String?), Never> {
        responsePublisherSubject.eraseToAnyPublisher()
    }

    init(serializer: Serializing, logger: ConsoleLogging) {
        self.serializer = serializer
        self.logger = logger
    }

    func dispatchEnvelope(_ envelope: String, topic: String) {
        manageSubscription(topic, envelope)
    }


    public func requestSubscription<RequestParams: Codable>(on method: String) -> AnyPublisher<RequestSubscriptionPayload<RequestParams>, Never> {
        return requestPublisher
            .filter { rpcRequest in
                return rpcRequest.request.method == method
            }
            .compactMap { [weak self] topic, rpcRequest in
                do {
                    guard let id = rpcRequest.id, let request = try rpcRequest.params?.get(RequestParams.self) else {
                        return nil
                    }
                    return RequestSubscriptionPayload(id: id, topic: topic, request: request, decryptedPayload: Data(), publishedAt: Date(), derivedTopic: nil)
                } catch {
                    self?.logger.debug(error)
                }
                return nil
            }

            .eraseToAnyPublisher()
    }

    private func manageSubscription(_ topic: String, _ encodedEnvelope: String) {
        if let (deserializedJsonRpcRequest, _, _): (RPCRequest, String?, Data) = serializer.tryDeserialize(topic: topic, encodedEnvelope: encodedEnvelope) {
            handleRequest(topic: topic, request: deserializedJsonRpcRequest)
        } else if let (response, derivedTopic, _): (RPCResponse, String?, Data) = serializer.tryDeserialize(topic: topic, encodedEnvelope: encodedEnvelope) {
//            handleResponse(topic: topic, response: response, publishedAt: publishedAt, derivedTopic: derivedTopic)
        } else {
            logger.debug("Networking Interactor - Received unknown object type from networking relay")
        }
    }

    private func handleRequest(topic: String, request: RPCRequest) {
        do {
//            try rpcHistory.set(request, forTopic: topic, emmitedBy: .remote)
            requestPublisherSubject.send((topic, request))
        } catch {
            logger.debug(error)
        }
    }
}
