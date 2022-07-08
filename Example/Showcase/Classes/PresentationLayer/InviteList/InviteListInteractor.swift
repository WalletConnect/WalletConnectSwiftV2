import Chat
import WalletConnectUtils

final class InviteListInteractor {
    private let chatService: ChatService

    init(chatService: ChatService) {
        self.chatService = chatService
    }

    func getInvites() async -> [Invite] {
        return await chatService.getInvites(account: ChatService.selfAccount)
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
