final class InviteInteractor {
    private let chatService: ChatService

    init(chatService: ChatService) {
        self.chatService = chatService
    }

    func invite(peerAccount: Account, message: String, selfAccount: Account) async {
        try! await chatService.invite(peerAccount: peerAccount, message: message)
    }
}
