import Foundation
import WalletConnectRelay

final class WelcomeInteractor {
    private let chatService: ChatService
    private let accountStorage: AccountStorage

    init(chatService: ChatService, accountStorage: AccountStorage) {
        self.chatService = chatService
        self.accountStorage = accountStorage
    }

    var account: Account? {
        return accountStorage.account
    }

    func isAuthorized() -> Bool {
        accountStorage.account != nil
    }

    func trackConnection() -> Stream<SocketConnectionStatus> {
        return chatService.connectionPublisher
    }
}
