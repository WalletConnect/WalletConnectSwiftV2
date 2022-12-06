import Foundation
import WalletConnectChat

final class Application {
    lazy var chatService: ChatService = {
        return ChatService(client: Chat.instance)
    }()

    lazy var accountStorage: AccountStorage = {
        return AccountStorage(defaults: .standard)
    }()

    lazy var registerService: RegisterService = {
        return RegisterService(chatService: chatService)
    }()
}
