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
        return try await getRecords(topic: topic, count: count, direction: direction).map { $0.object }
    }

    public func getRecords<T: Codable>(topic: String, count: Int, direction: GetMessagesPayload.Direction) async throws -> [HistoryRecord<T>] {
        let payload = GetMessagesPayload(topic: topic, originId: nil, messageCount: count, direction: direction)
        let response = try await historyNetworkService.getMessages(payload: payload, historyUrl: historyUrl)

        return response.messages.compactMap { payload in
            do {
                let (request, _, _): (RPCRequest, _, _) = try serializer.deserialize(
                    topic: topic,
                    encodedEnvelope: payload
                )

                guard
                    let id = request.id,
                    let object = try request.params?.get(T.self)
                else { return nil }

                return HistoryRecord<T>(id: id, object: object)
            } catch {
                fatalError(error.localizedDescription)
            }
        }
    }
}
