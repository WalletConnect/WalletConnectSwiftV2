import Foundation
import WalletConnectChat

final class Application {

    lazy var chatService: ChatService = {
        return ChatService(accountStorage: accountStorage)
    }()

    lazy var accountStorage: AccountStorage = {
        return AccountStorage(defaults: .standard)
    }()
}
