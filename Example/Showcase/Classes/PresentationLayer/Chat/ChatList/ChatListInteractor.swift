import WalletConnectChat

final class ChatListInteractor {

    private let chatService: ChatService
    private let accountStorage: AccountStorage

    init(chatService: ChatService, accountStorage: AccountStorage) {
        self.chatService = chatService
        self.accountStorage = accountStorage
    }

    func getThreads(account: Account) async -> [WalletConnectChat.Thread] {
        return await chatService.getThreads(account: account)
    }

    func threadsSubscription() -> Stream<WalletConnectChat.Thread> {
        return chatService.threadPublisher
    }

    func getInvites(account: Account) async -> [Invite] {
        return await chatService.getInvites(account: account)
    }

    func invitesSubscription() -> Stream<Invite> {
        return chatService.invitePublisher
    }

    func logout() {
        accountStorage.account = nil
    }
}
