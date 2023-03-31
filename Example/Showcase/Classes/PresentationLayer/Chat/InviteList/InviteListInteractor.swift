import WalletConnectChat

final class InviteListInteractor {
    private let chatService: ChatService

    init(chatService: ChatService) {
        self.chatService = chatService
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

    func accept(invite: ReceivedInvite) async throws {
        try await chatService.accept(invite: invite)
    }

    func reject(invite: ReceivedInvite) async throws {
        try await chatService.reject(invite: invite)
    }
}
