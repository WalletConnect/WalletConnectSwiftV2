import Foundation
import Combine

import WalletConnectRelay
import WalletConnectPairing
import Auth

final class WelcomeInteractor {
    private var disposeBag = Set<AnyCancellable>()
    
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
    
    func generateUri() async -> WalletConnectURI {
        return try! await Pair.instance.create()
    }
}

protocol IATProvider {
    var iat: String { get }
}

struct DefaultIATProvider: IATProvider {
    var iat: String {
        return ISO8601DateFormatter().string(from: Date())
    }
}
