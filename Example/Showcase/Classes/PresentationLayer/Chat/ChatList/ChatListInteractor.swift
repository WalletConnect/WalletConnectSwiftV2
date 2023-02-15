import WalletConnectChat

final class ChatListInteractor {

    private let chatService: ChatService
    private let accountStorage: AccountStorage

    init(chatService: ChatService, accountStorage: AccountStorage) {
        self.chatService = chatService
        self.accountStorage = accountStorage
    }

    func getThreads() -> [WalletConnectChat.Thread] {
        return chatService.getThreads()
    }

    func threadsSubscription() -> Stream<[WalletConnectChat.Thread]> {
        return chatService.threadPublisher
    }

    func getInvites() -> [ReceivedInvite] {
        return chatService.getReceivedInvites()
    }

    func receivedInvitesSubscription() -> Stream<[ReceivedInvite]> {
        return chatService.receivedInvitePublisher
    }

    func logout() async throws {
        guard let importAccount = accountStorage.importAccount else { return }
        try await chatService.goPrivate(account: importAccount.account)
        try await chatService.unregister(account: importAccount.account, privateKey: importAccount.privateKey)
        accountStorage.importAccount = nil
    }
}
