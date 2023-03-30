import WalletConnectChat

final class InviteListInteractor {
    private let chatService: ChatService

    init(chatService: ChatService) {
        self.chatService = chatService
    }

    func getReceivedInvites() -> [ReceivedInvite] {
        return chatService.getReceivedInvites()
    }

    func getSentInvites() -> [SentInvite] {
        return chatService.getSentInvites()
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
