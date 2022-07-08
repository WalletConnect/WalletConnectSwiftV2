import Chat

final class ChatListInteractor {

    private let chatService: ChatService

    init(chatService: ChatService) {
        self.chatService = chatService
    }

    func getThreads() async -> [Chat.Thread] {
        return await chatService.getThreads()
    }

    func threadsSubscription() -> Stream<Chat.Thread> {
        return chatService.threadPublisher
    }
}
