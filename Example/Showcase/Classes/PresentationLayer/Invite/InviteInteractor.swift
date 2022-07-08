final class InviteInteractor {
    private let chatService: ChatService

    init(chatService: ChatService) {
        self.chatService = chatService
    }

    func invite(account: String, message: String) async {
//        try! await chatService.invite(peerPubkey: <#T##String#>, peerAccount: <#T##Account#>, message: message, selfAccount: ChatService.selfAccount)
    }
}
