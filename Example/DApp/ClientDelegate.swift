
import WalletConnect
import Foundation


class ClientDelegate: WalletConnectClientDelegate {
    var client: WalletConnectClient
    var onSessionSettled: ((Session)->())?
    var onPairingSettled: ((Pairing)->())?
    var onSessionProposal: ((Session.Proposal)->())?
    var onSessionRequest: ((Request)->())?
    var onSessionRejected: ((String, Reason)->())?
    var onSessionDelete: (()->())?
    var onSessionUpgrade: ((String, Session.Permissions)->())?
    var onSessionUpdate: ((String, Set<String>)->())?
    var onNotificationReceived: ((Session.Notification, String)->())?
    var onPairingUpdate: ((String, AppMetadata)->())?
    
    static var shared: ClientDelegate = ClientDelegate()
    private init() {
        let metadata = AppMetadata(
            name: "Dapp Example",
            description: "a description",
            url: "wallet.connect",
            icons: ["https://gblobscdn.gitbook.com/spaces%2F-LJJeCjcLrr53DcT1Ml7%2Favatar.png?alt=media"])
        self.client = WalletConnectClient(
            metadata: metadata,
            projectId: "52af113ee0c1e1a20f4995730196c13e",
            isController: false,
            relayHost: "relay.dev.walletconnect.com"
        )
        client.delegate = self
    }
    
    func didReject(pendingSessionTopic: String, reason: Reason) {
        onSessionRejected?(pendingSessionTopic, reason)
    }
    func didSettle(session: Session) {
        onSessionSettled?(session)
    }
    func didSettle(pairing: Pairing) {
        onPairingSettled?(pairing)
    }
    func didReceive(sessionProposal: Session.Proposal) {
        onSessionProposal?(sessionProposal)
    }
    func didReceive(sessionRequest: Request) {
        onSessionRequest?(sessionRequest)
    }
    func didDelete(sessionTopic: String, reason: Reason) {
        onSessionDelete?()
    }
    func didUpgrade(sessionTopic: String, permissions: Session.Permissions) {
        onSessionUpgrade?(sessionTopic, permissions)
    }
    func didUpdate(sessionTopic: String, accounts: Set<String>) {
        onSessionUpdate?(sessionTopic, accounts)
    }
    func didReceive(notification: Session.Notification, sessionTopic: String) {
        onNotificationReceived?(notification, sessionTopic)
    }
    func didUpdate(pairingTopic: String, appMetadata: AppMetadata) {
        onPairingUpdate?(pairingTopic, appMetadata)
    }
}
