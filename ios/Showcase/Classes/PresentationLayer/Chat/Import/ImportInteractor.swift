final class ImportInteractor {

    private let chatService: ChatService
    private let accountStorage: AccountStorage

    init(chatService: ChatService, accountStorage: AccountStorage) {
        self.chatService = chatService
        self.accountStorage = accountStorage
    }

    func save(importAccount: ImportAccount) {
        accountStorage.importAccount = importAccount
    }

    func register(importAccount: ImportAccount) async throws {
        try await chatService.register(account: importAccount.account, privateKey: importAccount.privateKey)
    }
}
