import Foundation
import Chat

final class Application {

    let chatService: ChatService = {
        return ChatService(client: ChatFactory.create())
    }()
}
