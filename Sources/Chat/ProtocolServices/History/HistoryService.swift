import Foundation

final class HistoryService {

    private let historyClient: HistoryClient
    private let seiralizer: Serializing

    init(historyClient: HistoryClient, seiralizer: Serializing) {
        self.historyClient = historyClient
        self.seiralizer = seiralizer
    }

    func register() async throws {
        try await historyClient.register(tags: ["2002"])
    }

    func fetchMessageHistory(thread: Thread) async throws -> [Message] {
        let wrappers: [MessagePayload.Wrapper] = try await historyClient.getMessages(
            topic: thread.topic,
            count: 200, direction: .backward
        )

        return wrappers.map { wrapper in
            let (messagePayload, messageClaims) = try! MessagePayload.decodeAndVerify(from: wrapper)

            let authorAccount = messagePayload.recipientAccount == thread.selfAccount
                ? thread.peerAccount
                : thread.selfAccount

            return Message(
                topic: thread.topic,
                message: messagePayload.message,
                authorAccount: authorAccount,
                timestamp: messageClaims.iat)
        }
    }
}
