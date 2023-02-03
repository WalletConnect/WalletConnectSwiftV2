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

    func threadsSubscription() -> Stream<WalletConnectChat.Thread> {
        return chatService.threadPublisher
    }

    func getInvites() -> [Invite] {
        return chatService.getInvites()
    }

    func invitesSubscription() -> Stream<Invite> {
        return chatService.invitePublisher
    }

    func logout() {
        accountStorage.account = nil
    }
}
