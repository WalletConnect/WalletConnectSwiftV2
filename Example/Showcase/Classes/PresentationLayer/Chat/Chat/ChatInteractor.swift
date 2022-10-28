import Foundation
import WalletConnectChat

final class ChatInteractor {

    private let chatService: ChatService

    init(chatService: ChatService) {
        self.chatService = chatService
    }

    func getMessages(thread: WalletConnectChat.Thread) async -> [Message] {
        return await chatService.getMessages(thread: thread)
    }

    func messagesSubscription() -> Stream<Message> {
        return chatService.messagePublisher
    }

    func sendMessage(topic: String, message: String) async throws {
        try await chatService.sendMessage(topic: topic, message: message)
    }
}
