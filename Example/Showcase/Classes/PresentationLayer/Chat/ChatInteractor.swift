final class ChatInteractor {

    private let chatService: ChatService

    init(chatService: ChatService) {
        self.chatService = chatService
    }

    func getCurrentAccount() async -> String {
        return await chatService.getAuthorAccount()
    }

    func getMessages(topic: String) -> MessageStream {
        return chatService.getMessages(topic: topic)
    }

    func sendMessage(text: String) async throws {
        try await chatService.sendMessage(text: text)
    }
}
