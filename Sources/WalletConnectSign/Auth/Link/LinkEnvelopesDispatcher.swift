
#if os(iOS)
import UIKit


import Combine
class LinkEnvelopesDispatcher {
    enum Errors: Error {
        case invalidURL
    }
    private let serializer: Serializing
    private let logger: ConsoleLogging
    private var publishers = Set<AnyCancellable>()
    private let rpcHistory: RPCHistory


    private let requestPublisherSubject = PassthroughSubject<(topic: String, request: RPCRequest), Never>()
    private let responsePublisherSubject = PassthroughSubject<(topic: String, request: RPCRequest, response: RPCResponse, publishedAt: Date, derivedTopic: String?), Never>()

    public var requestPublisher: AnyPublisher<(topic: String, request: RPCRequest), Never> {
        requestPublisherSubject.eraseToAnyPublisher()
    }

    private var responsePublisher: AnyPublisher<(topic: String, request: RPCRequest, response: RPCResponse, publishedAt: Date, derivedTopic: String?), Never> {
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

    func dispatchEnvelope(_ envelope: String, topic: String) throws {
        guard let envelopeURL = URL(string: envelope) else {
            throw Errors.invalidURL
        }

        // Use URLComponents to parse the URL for query items
        guard let components = URLComponents(url: envelopeURL, resolvingAgainstBaseURL: true),
              let wcEnvelope = components.queryItems?.first(where: { $0.name == "wc_envelope" })?.value else {
            throw Errors.invalidURL
        }
        manageSubscription(topic, wcEnvelope)
    }

    func request(request: RPCRequest, walletUniversalLink: String) async throws -> String {

        let envelope = try serializer.serializeEnvelopeType2(encodable: request)

        guard var components = URLComponents(string: walletUniversalLink) else { throw URLError(.badURL) }

        components.queryItems = [URLQueryItem(name: "wc_envelope", value: envelope)]

        guard let finalURL = components.url else { throw URLError(.badURL) }


//        await UIApplication.shared.open(finalURL)
        return finalURL.absoluteString
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
            try rpcHistory.set(request, forTopic: topic, emmitedBy: .remote, transportType: .linkMode)
            requestPublisherSubject.send((topic, request))
        } catch {
            logger.debug(error)
        }
    }
}
#endif
