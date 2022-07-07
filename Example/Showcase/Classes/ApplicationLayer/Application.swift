import Foundation

final class Application {

    let chatService: ChatService = {
        return ChatService()
    }()
}
