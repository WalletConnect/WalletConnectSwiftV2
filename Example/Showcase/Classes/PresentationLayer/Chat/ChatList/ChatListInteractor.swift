import WalletConnectChat

final class ChatListInteractor {

    private let chatService: ChatService
    private let accountStorage: AccountStorage

    var account: Account? {
        return accountStorage.importAccount?.account
    }

    init(chatService: ChatService, accountStorage: AccountStorage) {
        self.chatService = chatService
        self.accountStorage = accountStorage
    }

    func getThreads(account: Account) -> [WalletConnectChat.Thread] {
        return chatService.getThreads(account: account)
    }

    func threadsSubscription() -> Stream<[WalletConnectChat.Thread]> {
        return chatService.threadPublisher
    }

    func getReceivedInvites(account: Account) -> [ReceivedInvite] {
        return chatService.getReceivedInvites(account: account)
    }

    func getSentInvites(account: Account) -> [SentInvite] {
        return chatService.getSentInvites(account: account)
    }

    func receivedInvitesSubscription() -> Stream<[ReceivedInvite]> {
        return chatService.receivedInvitePublisher
    }

    func sentInvitesSubscription() -> Stream<[SentInvite]> {
        return chatService.sentInvitePublisher
    }

    func setupSubscriptions(account: Account) {
        chatService.setupSubscriptions(account: account)
    }

    func logout() async throws {
        guard let importAccount = accountStorage.importAccount else { return }
        try await chatService.goPrivate(account: importAccount.account)
        try await chatService.unregister(account: importAccount.account, importAccount: importAccount)
        accountStorage.importAccount = nil
    }
}
