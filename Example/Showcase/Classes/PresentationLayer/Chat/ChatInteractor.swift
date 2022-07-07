final class ChatInteractor {

    private let chatService: ChatService

    init(chatService: ChatService) {
        self.chatService = chatService
    }

    func getMessages(topic: String) -> Stream<[Message]> {
        return chatService.getMessages(topic: topic)
    }

    func sendMessage(text: String) async throws {
        try await chatService.sendMessage(text: text)
    }
}
