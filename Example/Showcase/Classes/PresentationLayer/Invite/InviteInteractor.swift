import WalletConnectUtils

final class InviteInteractor {
    private let chatService: ChatService

    init(chatService: ChatService) {
        self.chatService = chatService
    }

    func invite(account: String, message: String) async {
        let peerAccount = Account(account)!
        let publicKey = try! await chatService.resolve(account: peerAccount)
        try! await chatService.invite(peerPubkey: publicKey, peerAccount: peerAccount, message: message, selfAccount: ChatService.selfAccount)
    }
}
