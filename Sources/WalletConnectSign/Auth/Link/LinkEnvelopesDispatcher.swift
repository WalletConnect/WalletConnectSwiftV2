
#if os(iOS)
import UIKit
#endif

import Combine

final class LinkEnvelopesDispatcher {
    enum Errors: Error {
        case invalidURL
        case envelopeNotFound
        case topicNotFound
        case failedToOpenUniversalLink(String)
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
        logger.debug("will dispatch an envelope: \(envelope)")
        guard let envelopeURL = URL(string: envelope),
        let components = URLComponents(url: envelopeURL, resolvingAgainstBaseURL: true) else {
            throw Errors.invalidURL
        }

        guard let wcEnvelope = components.queryItems?.first(where: { $0.name == "wc_ev" })?.value else {
            logger.error(Errors.envelopeNotFound.localizedDescription)
            throw Errors.envelopeNotFound
        }
        guard let topic = components.queryItems?.first(where: { $0.name == "topic" })?.value else {
            logger.error(Errors.topicNotFound.localizedDescription)
            throw Errors.topicNotFound
        }
        manageEnvelope(topic, wcEnvelope)
    }

    func request(topic: String, request: RPCRequest, peerUniversalLink: String, envelopeType: Envelope.EnvelopeType) async throws -> String {

        logger.debug("Will send request with link mode")
        try rpcHistory.set(request, forTopic: topic, emmitedBy: .local, transportType: .relay)

        let envelopeUrl: URL
        do {
            envelopeUrl = try serializeAndCreateUrl(peerUniversalLink: peerUniversalLink, encodable: request, envelopeType: envelopeType, topic: topic)

            logger.debug("Will try to open envelopeUrl: \(envelopeUrl)")

            try await withCheckedThrowingContinuation { continuation in
                if isRunningTests() {
                    continuation.resume(returning: ())
                    return
                }
                DispatchQueue.main.async { [weak self] in
                    self?.logger.debug("Will open universal link")
                    UIApplication.shared.open(envelopeUrl, options: [.universalLinksOnly: true]) { success in
                        if success {
                            continuation.resume(returning: ())
                        } else {
                            continuation.resume(throwing: Errors.failedToOpenUniversalLink(envelopeUrl.absoluteString))
                        }
                    }
                }
            }

        } catch {
            logger.error("Failed to open url, error: \(error) ")
            if let id = request.id {
                rpcHistory.delete(id: id)
            }
            throw error
        }

        return envelopeUrl.absoluteString
    }

    func respond(topic: String, response: RPCResponse, peerUniversalLink: String, envelopeType: Envelope.EnvelopeType) async throws -> String {
        logger.debug("will redpond for a request id: \(String(describing: response.id))")
        try rpcHistory.validate(response)
        let envelopeUrl = try serializeAndCreateUrl(peerUniversalLink: peerUniversalLink, encodable: response, envelopeType: envelopeType, topic: topic)
        logger.debug("Prepared envelopeUrl: \(envelopeUrl)")

        try await withCheckedThrowingContinuation { continuation in
            if isRunningTests() {
                continuation.resume(returning: ())
                return
            }
            DispatchQueue.main.async { [unowned self] in
                logger.debug("Will open universal link")
                UIApplication.shared.open(envelopeUrl, options: [.universalLinksOnly: true]) { success in
                    if success {
                        continuation.resume(returning: ())
                    } else {
                        continuation.resume(throwing: Errors.failedToOpenUniversalLink(envelopeUrl.absoluteString))
                    }
                }
            }
        }

        try rpcHistory.resolve(response)

        return envelopeUrl.absoluteString
    }

    public func respondError(topic: String, requestId: RPCID, peerUniversalLink: String, reason: Reason, envelopeType: Envelope.EnvelopeType) async throws -> String {
        logger.debug("Will respond with error, peerUniversalLink: \(peerUniversalLink)")
        let error = JSONRPCError(code: reason.code, message: reason.message)
        let response = RPCResponse(id: requestId, error: error)
        return try await respond(topic: topic, response: response, peerUniversalLink: peerUniversalLink, envelopeType: envelopeType)
    }

    private func serializeAndCreateUrl(peerUniversalLink: String, encodable: Encodable, envelopeType: Envelope.EnvelopeType, topic: String) throws -> URL {
        let envelope = try serializer.serialize(topic: topic, encodable: encodable, envelopeType: envelopeType, codingType: .base64UrlEncoded)

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
                    return RequestSubscriptionPayload(id: id, topic: topic, request: request, decryptedPayload: Data(), publishedAt: Date(), derivedTopic: nil, encryptedMessage: "", attestation: nil)
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
            logger.debug("handling link mode request")
            try rpcHistory.set(request, forTopic: topic, emmitedBy: .remote, transportType: .linkMode)
            requestPublisherSubject.send((topic, request))
        } catch {
            logger.debug("Handling link mode request failed: \(error)")
        }
    }

    private func handleResponse(topic: String, response: RPCResponse) {
        do {
            logger.debug("handling link mode response")
            let record = try rpcHistory.resolve(response)
            responsePublisherSubject.send((topic, record.request, response))
        } catch {
            logger.debug("Handling link mode response failed: \(error)")
        }
    }

    func isRunningTests() -> Bool {
        return ProcessInfo.processInfo.arguments.contains("isTesting")
    }
}
