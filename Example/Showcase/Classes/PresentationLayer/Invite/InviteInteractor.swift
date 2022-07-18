final class InviteInteractor {
    private let chatService: ChatService

    init(chatService: ChatService) {
        self.chatService = chatService
    }

    func invite(peerAccount: Account, message: String, selfAccount: Account) async {
        let publicKey = try! await chatService.resolve(account: peerAccount)
        try! await chatService.invite(peerPubkey: publicKey, peerAccount: peerAccount, message: message, selfAccount: selfAccount)
    }
}
