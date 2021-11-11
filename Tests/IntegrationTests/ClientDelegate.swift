
import Foundation
@testable import WalletConnect

class ClientDelegate: WalletConnectClientDelegate {
    var client: WalletConnectClient
    var onSessionSettled: ((Session)->())?
    var onPairingSettled: ((PairingType.Settled)->())?
    var onSessionProposal: ((SessionProposal)->())?
    var onSessionRequest: ((SessionRequest)->())?
    var onSessionRejected: ((String, SessionType.Reason)->())?
    var onSessionDelete: (()->())?
    var onSessionUpgrade: ((String, SessionType.Permissions)->())?
    var onSessionUpdate: ((String, Set<String>)->())?
    var onNotificationReceived: ((WalletConnect.Notification, String)->())?
    var onPairingUpdate: ((String, AppMetadata)->())?
    
    internal init(client: WalletConnectClient) {
        self.client = client
        client.delegate = self
    }
    
    func didReject(sessionPendingTopic: String, reason: SessionType.Reason) {
        onSessionRejected?(sessionPendingTopic, reason)
    }
    func didSettle(session: Session) {
        onSessionSettled?(session)
    }
    func didSettle(pairing: PairingType.Settled) {
        onPairingSettled?(pairing)
    }
    func didReceive(sessionProposal: SessionProposal) {
        onSessionProposal?(sessionProposal)
    }
    func didReceive(sessionRequest: SessionRequest) {
        onSessionRequest?(sessionRequest)
    }
    func didDelete(sessionTopic: String, reason: SessionType.Reason) {
        onSessionDelete?()
    }
    func didUpgrade(sessionTopic: String, permissions: SessionType.Permissions) {
        onSessionUpgrade?(sessionTopic, permissions)
    }
    func didUpdate(sessionTopic: String, accounts: Set<String>) {
        onSessionUpdate?(sessionTopic, accounts)
    }
    func didReceive(notification: WalletConnect.Notification, sessionTopic: String) {
        onNotificationReceived?(notification, sessionTopic)
    }
    func didUpdate(pairingTopic: String, appMetadata: AppMetadata) {
        onPairingUpdate?(pairingTopic, appMetadata)
    }
}
