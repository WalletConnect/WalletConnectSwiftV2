import WalletConnect
import Relayer

class ClientDelegate: WalletConnectClientDelegate {
    var client: WalletConnectClient
    var onSessionSettled: ((Session)->())?
    var onSessionResponse: ((Response)->())?
    var onSessionDelete: (()->())?
    
    static var shared: ClientDelegate = ClientDelegate()
    private init() {
        let metadata = AppMetadata(
            name: "Swift Dapp",
            description: "a description",
            url: "wallet.connect",
            icons: ["https://gblobscdn.gitbook.com/spaces%2F-LJJeCjcLrr53DcT1Ml7%2Favatar.png?alt=media"])
        let relayer = Relayer()
        self.client = WalletConnectClient(
            metadata: metadata,
            projectId: "52af113ee0c1e1a20f4995730196c13e",
            isController: false,
            relayHost: "relay.dev.walletconnect.com"
        )
        client.delegate = self
    }
	
    func didSettle(session: Session) {
        onSessionSettled?(session)
    }

    func didDelete(sessionTopic: String, reason: Reason) {
        onSessionDelete?()
    }

    func didReceive(sessionResponse: Response) {
        onSessionResponse?(sessionResponse)
    }
    
    func didUpdate(sessionTopic: String, accounts: Set<String>) {
    }
    
    func didUpgrade(sessionTopic: String, permissions: Session.Permissions) {
    }
}
