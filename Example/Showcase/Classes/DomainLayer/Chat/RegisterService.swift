import Foundation
import WalletConnectUtils

final class RegisterService {

    private let chatService: ChatService

    init(chatService: ChatService) {
        self.chatService = chatService
    }

    func register(account: Account) async {
        try! await chatService.register(account: account)
        print("Account: \(account.absoluteString) registered")
    }
}
