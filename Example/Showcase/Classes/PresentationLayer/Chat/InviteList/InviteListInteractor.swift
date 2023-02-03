import WalletConnectChat

final class InviteListInteractor {
    private let chatService: ChatService

    init(chatService: ChatService) {
        self.chatService = chatService
    }

    func getInvites() -> [Invite] {
        return chatService.getInvites()
    }

    func invitesSubscription() -> Stream<Invite> {
        return chatService.invitePublisher
    }

    func accept(invite: Invite) async {
        try! await chatService.accept(invite: invite)
    }

    func reject(invite: Invite) async {
        try! await chatService.reject(invite: invite)
    }
}
