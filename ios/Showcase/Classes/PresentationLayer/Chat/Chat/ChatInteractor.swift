import Foundation
import WalletConnectChat

final class ChatInteractor {

    private let chatService: ChatService

    init(chatService: ChatService) {
        self.chatService = chatService
    }

    func getMessages(thread: WalletConnectChat.Thread) -> [Message] {
        return chatService.getMessages(thread: thread)
    }

    func messagesSubscription(thread: WalletConnectChat.Thread) -> Stream<[Message]> {
        return chatService.messagePublisher(thread: thread)
    }

    func sendMessage(topic: String, message: String) async throws {
        try await chatService.sendMessage(topic: topic, message: message)
    }
}
