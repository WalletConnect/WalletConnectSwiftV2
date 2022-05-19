import WalletConnectAuth
import WalletConnectRelay

class ClientDelegate: AuthClientDelegate {
    var client: AuthClient
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
        let relayClient = RelayClient(relayHost: "relay.walletconnect.com", projectId: "8ba9ee138960775e5231b70cc5ef1c3a")
        self.client = AuthClient(metadata: metadata, relayClient: relayClient)
        client.logger.setLogging(level: .debug)
        client.delegate = self
    }
    
    func didConnect() {
        print("Client connected")
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
    
    func didUpdate(sessionTopic: String, accounts: Set<Account>) {
    }
    
    func didReject(proposal: Session.Proposal, reason: Reason) {
        
    }
    
    func didUpdate(sessionTopic: String, namespaces: [String : SessionNamespace]) {
        
    }
}
