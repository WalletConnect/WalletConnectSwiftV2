import Foundation

public final class HistoryClient {

    private let historyUrl: String
    private let relayUrl: String
    private let serializer: Serializer
    private let historyNetworkService: HistoryNetworkService

    init(historyUrl: String, relayUrl: String, serializer: Serializer, historyNetworkService: HistoryNetworkService) {
        self.historyUrl = historyUrl
        self.relayUrl = relayUrl
        self.serializer = serializer
        self.historyNetworkService = historyNetworkService
    }

    public func register(tags: [String]) async throws {
        let payload = RegisterPayload(tags: tags, relayUrl: relayUrl)
        try await historyNetworkService.registerTags(payload: payload, historyUrl: historyUrl)
    }

    public func getMessages<T: Codable>(topic: String, count: Int, direction: GetMessagesPayload.Direction) async throws -> [T] {
        let payload = GetMessagesPayload(topic: topic, originId: nil, messageCount: count, direction: direction)
        let response = try await historyNetworkService.getMessages(payload: payload, historyUrl: historyUrl)

        let objects = response.messages.compactMap { payload in
            do {
                let (request, _, _): (RPCRequest, _, _) = try serializer.deserialize(
                    topic: topic,
                    encodedEnvelope: payload
                )
                return try request.params?.get(T.self)
            } catch {
                fatalError(error.localizedDescription)
            }
        }

        return objects
    }
}
