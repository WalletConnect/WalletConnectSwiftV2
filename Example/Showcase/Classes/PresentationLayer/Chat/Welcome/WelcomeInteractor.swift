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

    var importAccount: ImportAccount? {
        return accountStorage.importAccount
    }

    func isAuthorized() -> Bool {
        accountStorage.importAccount != nil
    }

    func trackConnection() -> Stream<SocketConnectionStatus> {
        return chatService.connectionPublisher
    }
    
    func generateUri() async -> WalletConnectURI {
        return try! await Pair.instance.create()
    }

    func goPublic() async throws {
        guard let importAccount = importAccount else { return }
        try await chatService.goPublic(account: importAccount.account, privateKey: importAccount.privateKey)
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
