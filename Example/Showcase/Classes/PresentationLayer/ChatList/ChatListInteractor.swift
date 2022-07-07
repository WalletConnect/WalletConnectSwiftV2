final class ChatListInteractor {

    private let chatService: ChatService

    init(chatService: ChatService) {
        self.chatService = chatService
    }

    func getThreads() -> Stream<[Thread]> {
        return chatService.getThreads()
    }
}
