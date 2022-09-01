import Foundation
import Combine
import JSONRPC
import WalletConnectRelay
import WalletConnectUtils
import WalletConnectKMS

public class NetworkingInteractor: NetworkInteracting {
    private var publishers = Set<AnyCancellable>()
    private let relayClient: RelayClient
    private let serializer: Serializing
    private let rpcHistory: RPCHistory
    private let logger: ConsoleLogging

    private let requestPublisherSubject = PassthroughSubject<RequestSubscriptionPayload, Never>()
    private let responsePublisherSubject = PassthroughSubject<ResponseSubscriptionPayload, Never>()

    public var requestPublisher: AnyPublisher<RequestSubscriptionPayload, Never> {
        requestPublisherSubject.eraseToAnyPublisher()
    }

    public var responsePublisher: AnyPublisher<ResponseSubscriptionPayload, Never> {
        responsePublisherSubject.eraseToAnyPublisher()
    }

    public var socketConnectionStatusPublisher: AnyPublisher<SocketConnectionStatus, Never>

    public init(
        relayClient: RelayClient,
        serializer: Serializing,
        logger: ConsoleLogging,
        rpcHistory: RPCHistory
    ) {
        self.relayClient = relayClient
        self.serializer = serializer
        self.rpcHistory = rpcHistory
        self.logger = logger
        self.socketConnectionStatusPublisher = relayClient.socketConnectionStatusPublisher
        relayClient.messagePublisher.sink { [unowned self] (topic, message) in
            manageSubscription(topic, message)
        }
        .store(in: &publishers)
    }

    public func subscribe(topic: String) async throws {
        try await relayClient.subscribe(topic: topic)
    }

    public func unsubscribe(topic: String) {
        relayClient.unsubscribe(topic: topic) { [unowned self] error in
            if let error = error {
                logger.error(error)
            } else {
                rpcHistory.deleteAll(forTopic: topic)
            }
        }
    }

    public func request(_ request: RPCRequest, topic: String, tag: Int, envelopeType: Envelope.EnvelopeType) async throws {
        try rpcHistory.set(request, forTopic: topic, emmitedBy: .local)
        let message = try! serializer.serialize(topic: topic, encodable: request, envelopeType: envelopeType)
        try await relayClient.publish(topic: topic, payload: message, tag: tag)
    }

    /// Completes with an acknowledgement from the relay network.
    /// completes with error if networking client was not able to send a message
    /// TODO - relay client should provide async function - continualion should be removed from here
    public func requestNetworkAck(_ request: RPCRequest, topic: String, tag: Int) async throws {
        do {
            try rpcHistory.set(request, forTopic: topic, emmitedBy: .local)
            let message = try serializer.serialize(topic: topic, encodable: request)
            return try await withCheckedThrowingContinuation { continuation in
                relayClient.publish(topic: topic, payload: message, tag: tag) { error in
                    if let error = error {
                        continuation.resume(throwing: error)
                    } else {
                        continuation.resume()
                    }
                }
            }
        } catch {
            logger.error(error)
        }
    }

    public func respond(topic: String, response: RPCResponse, tag: Int, envelopeType: Envelope.EnvelopeType) async throws {
        try rpcHistory.resolve(response)
        let message = try! serializer.serialize(topic: topic, encodable: response, envelopeType: envelopeType)
        try await relayClient.publish(topic: topic, payload: message, tag: tag)
    }

    public func respondSuccess(topic: String, requestId: RPCID, tag: Int, envelopeType: Envelope.EnvelopeType) async throws {
        let response = RPCResponse(id: requestId, result: true)
        try await respond(topic: topic, response: response, tag: tag, envelopeType: envelopeType)
    }

    public func respondError(topic: String, requestId: RPCID, tag: Int, reason: Reason, envelopeType: Envelope.EnvelopeType) async throws {
        let error = JSONRPCError(code: reason.code, message: reason.message)
        let response = RPCResponse(id: requestId, error: error)
        try await respond(topic: topic, response: response, tag: tag, envelopeType: envelopeType)
    }

    private func manageSubscription(_ topic: String, _ encodedEnvelope: String) {
        if let deserializedJsonRpcRequest: RPCRequest = serializer.tryDeserialize(topic: topic, encodedEnvelope: encodedEnvelope) {
            handleRequest(topic: topic, request: deserializedJsonRpcRequest)
        } else if let response: RPCResponse = serializer.tryDeserialize(topic: topic, encodedEnvelope: encodedEnvelope) {
            handleResponse(response: response)
        } else {
            logger.debug("Networking Interactor - Received unknown object type from networking relay")
        }
    }

    private func handleRequest(topic: String, request: RPCRequest) {
        do {
            try rpcHistory.set(request, forTopic: topic, emmitedBy: .remote)
            let payload = RequestSubscriptionPayload(topic: topic, request: request)
            requestPublisherSubject.send(payload)
        } catch {
            logger.debug(error)
        }
    }

    private func handleResponse(response: RPCResponse) {
        do {
            try rpcHistory.resolve(response)
            let record = rpcHistory.get(recordId: response.id!)!
            responsePublisherSubject.send(ResponseSubscriptionPayload(topic: record.topic, response: response))
        } catch {
            logger.debug("Handle json rpc response error: \(error)")
        }
    }
}
