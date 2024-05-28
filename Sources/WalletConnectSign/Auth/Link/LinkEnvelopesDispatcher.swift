
import UIKit
import Combine

final class LinkEnvelopesDispatcher {
    enum Errors: Error {
        case invalidURL
        case envelopeNotFound
        case topicNotFound
    }
    private let serializer: Serializing
    private let logger: ConsoleLogging
    private var publishers = Set<AnyCancellable>()
    private let rpcHistory: RPCHistory


    private let requestPublisherSubject = PassthroughSubject<(topic: String, request: RPCRequest), Never>()
    private let responsePublisherSubject = PassthroughSubject<(topic: String, request: RPCRequest, response: RPCResponse), Never>()

    public var requestPublisher: AnyPublisher<(topic: String, request: RPCRequest), Never> {
        requestPublisherSubject.eraseToAnyPublisher()
    }

    private var responsePublisher: AnyPublisher<(topic: String, request: RPCRequest, response: RPCResponse), Never> {
        responsePublisherSubject.eraseToAnyPublisher()
    }

    init(
        serializer: Serializing,
        logger: ConsoleLogging,
        rpcHistory: RPCHistory
    ) {
        self.serializer = serializer
        self.logger = logger
        self.rpcHistory = rpcHistory
    }

    func dispatchEnvelope(_ envelope: String) throws {
        guard let envelopeURL = URL(string: envelope),
        let components = URLComponents(url: envelopeURL, resolvingAgainstBaseURL: true) else {
            throw Errors.invalidURL
        }

        guard let wcEnvelope = components.queryItems?.first(where: { $0.name == "wc_ev" })?.value else {
            throw Errors.envelopeNotFound
        }
        guard let topic = components.queryItems?.first(where: { $0.name == "topic" })?.value else {
            throw Errors.topicNotFound
        }
        manageEnvelope(topic, wcEnvelope)
    }

    func request(topic: String, request: RPCRequest, peerUniversalLink: String, envelopeType: Envelope.EnvelopeType) async throws -> String {

        try rpcHistory.set(request, forTopic: topic, emmitedBy: .local, transportType: .relay)

        let envelopeUrl: URL
        do {
            envelopeUrl = try serializeAndCreateUrl(peerUniversalLink: peerUniversalLink, encodable: request, envelopeType: envelopeType, topic: topic)

            DispatchQueue.main.async {
                UIApplication.shared.open(envelopeUrl, options: [.universalLinksOnly: true])
            }
        } catch {
            if let id = request.id {
                rpcHistory.delete(id: id)
            }
            throw error
        }

        return envelopeUrl.absoluteString
    }

    func respond(topic: String, response: RPCResponse, peerUniversalLink: String, envelopeType: Envelope.EnvelopeType) async throws -> String {
        try rpcHistory.validate(response)
        let envelopeUrl = try serializeAndCreateUrl(peerUniversalLink: peerUniversalLink, encodable: response, envelopeType: envelopeType, topic: topic)
        DispatchQueue.main.async {
            UIApplication.shared.open(envelopeUrl, options: [.universalLinksOnly: true])
        }
        try rpcHistory.resolve(response)

        return envelopeUrl.absoluteString
    }

    public func respondError(topic: String, requestId: RPCID, peerUniversalLink: String, reason: Reason, envelopeType: Envelope.EnvelopeType) async throws -> String {
        let error = JSONRPCError(code: reason.code, message: reason.message)
        let response = RPCResponse(id: requestId, error: error)
        return try await respond(topic: topic, response: response, peerUniversalLink: peerUniversalLink, envelopeType: envelopeType)
    }

    private func serializeAndCreateUrl(peerUniversalLink: String, encodable: Encodable, envelopeType: Envelope.EnvelopeType, topic: String) throws -> URL {
        let envelope = try serializer.serialize(topic: topic, encodable: encodable, envelopeType: envelopeType)

        guard var components = URLComponents(string: peerUniversalLink) else { throw URLError(.badURL) }

        components.queryItems = [URLQueryItem(name: "wc_ev", value: envelope), URLQueryItem(name: "topic", value: topic)]

        guard let finalURL = components.url else { throw URLError(.badURL) }
        return finalURL
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

    public func responseSubscription<Request: Codable, Response: Codable>(on request: ProtocolMethod) -> AnyPublisher<ResponseSubscriptionPayload<Request, Response>, Never> {
        return responsePublisher
            .filter { rpcRequest in
                return rpcRequest.request.method == request.method
            }
            .compactMap { topic, rpcRequest, rpcResponse  in
                guard
                    let id = rpcRequest.id,
                    let request = try? rpcRequest.params?.get(Request.self),
                    let response = try? rpcResponse.result?.get(Response.self) else { return nil }
                return ResponseSubscriptionPayload(id: id, topic: topic, request: request, response: response, publishedAt: Date(), derivedTopic: nil)
            }
            .eraseToAnyPublisher()
    }

    public func responseErrorSubscription<Request: Codable>(on request: ProtocolMethod) -> AnyPublisher<ResponseSubscriptionErrorPayload<Request>, Never> {
        return responsePublisher
            .filter { $0.request.method == request.method }
            .compactMap { topic, rpcRequest, rpcResponse in
                guard let id = rpcResponse.id, let request = try? rpcRequest.params?.get(Request.self), let error = rpcResponse.error else { return nil }
                return ResponseSubscriptionErrorPayload(id: id, topic: topic, request: request, error: error)
            }
            .eraseToAnyPublisher()
    }

    private func manageEnvelope(_ topic: String, _ encodedEnvelope: String) {
        if let result = serializer.tryDeserializeRequestOrResponse(topic: topic, codingType: .base64UrlEncoded, envelopeString: encodedEnvelope) {
            switch result {
            case .left(let result):
                handleRequest(topic: topic, request: result.request)
            case .right(let result):
                handleResponse(topic: topic, response: result.response)
            }
        } else {
            logger.debug("Link Dispatcher - Received unknown object type to dispatch")
        }
    }

    private func handleRequest(topic: String, request: RPCRequest) {
        do {
            try rpcHistory.set(request, forTopic: topic, emmitedBy: .remote, transportType: .linkMode)
            requestPublisherSubject.send((topic, request))
        } catch {
            logger.debug(error)
        }
    }

    private func handleResponse(topic: String, response: RPCResponse) {
        do {
            let record = try rpcHistory.resolve(response)
            responsePublisherSubject.send((topic, record.request, response))
        } catch {
            logger.debug("Handle json rpc response error: \(error)")
        }
    }
}
