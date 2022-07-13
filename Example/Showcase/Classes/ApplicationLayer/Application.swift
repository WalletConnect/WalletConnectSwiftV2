import Foundation
import Chat

final class Application {

    let chatService: ChatService = {
        return ChatService(client: ChatFactory.create())
    }()

    lazy var accountStorage: AccountStorage = {
        return AccountStorage(defaults: .standard)
    }()

    lazy var registerService: RegisterService = {
        return RegisterService(chatService: chatService)
    }()
}
