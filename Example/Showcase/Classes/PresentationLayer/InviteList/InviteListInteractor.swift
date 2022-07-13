import Chat
import WalletConnectUtils

final class InviteListInteractor {
    private let chatService: ChatService

    init(chatService: ChatService) {
        self.chatService = chatService
    }

    func getInvites(account: Account) async -> [Invite] {
        return await chatService.getInvites(account: account)
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
