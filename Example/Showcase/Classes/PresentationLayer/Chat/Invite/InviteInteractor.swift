import WalletConnectSigner

final class InviteInteractor {

    private let accountStorage: AccountStorage
    private let chatService: ChatService

    init(accountStorage: AccountStorage, chatService: ChatService) {
        self.accountStorage = accountStorage
        self.chatService = chatService
    }

    func invite(inviterAccount: Account, inviteeAccount: Account, message: String) async throws {
        try await chatService.invite(inviterAccount: inviterAccount, inviteeAccount: inviteeAccount, message: message)
    }

    func resolve(ens: String) async throws -> Account {
        let resolver = ENSResolverFactory(crypto: DefaultCryptoProvider()).create()
        let blochain = Blockchain("eip155:1")!
        return try await resolver.resolveAddress(ens: ens, blockchain: Blockchain("eip155:1")!)
    }
}
