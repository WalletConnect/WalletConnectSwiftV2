final class InviteInteractor {
    private let chatService: ChatService

    init(chatService: ChatService) {
        self.chatService = chatService
    }

    func invite(account: String) async {
        try! await chatService.invite(account: account)
    }
}
