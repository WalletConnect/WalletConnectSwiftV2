final class InviteListInteractor {
    private let chatService: ChatService

    init(chatService: ChatService) {
        self.chatService = chatService
    }

    func getInvites() -> Stream<[Invite]> {
        return chatService.getInvites()
    }

    func accept(invite: Invite) async {
        try! await chatService.accept(invite: invite)
    }

    func reject(invite: Invite) async {
        try! await chatService.reject(invite: invite)
    }
}
