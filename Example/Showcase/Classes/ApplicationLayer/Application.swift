import Foundation
import WalletConnectChat

final class Application {

    lazy var chatService: ChatService = {
        return ChatService()
    }()

    lazy var accountStorage: AccountStorage = {
        return AccountStorage(defaults: .standard)
    }()

    lazy var pushRegisterer: PushRegisterer = {
        return PushRegisterer()
    }()
}
