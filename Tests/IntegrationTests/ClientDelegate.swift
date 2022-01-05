
import Foundation
@testable import WalletConnect

class ClientDelegate: WalletConnectClientDelegate {
    var client: WalletConnectClient
    var onSessionSettled: ((Session)->())?
    var onPairingSettled: ((Pairing)->())?
    var onSessionProposal: ((Session.Proposal)->())?
    var onSessionRequest: ((SessionRequest)->())?
    var onSessionRejected: ((String, SessionType.Reason)->())?
    var onSessionDelete: (()->())?
    var onSessionUpgrade: ((String, Session.Permissions)->())?
    var onSessionUpdate: ((String, Set<String>)->())?
    var onNotificationReceived: ((SessionNotification, String)->())?
    var onPairingUpdate: ((String, AppMetadata)->())?
    
    internal init(client: WalletConnectClient) {
        self.client = client
        client.delegate = self
    }
    
    func didReject(pendingSessionTopic: String, reason: SessionType.Reason) {
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
    func didReceive(sessionRequest: SessionRequest) {
        onSessionRequest?(sessionRequest)
    }
    func didDelete(sessionTopic: String, reason: SessionType.Reason) {
        onSessionDelete?()
    }
    func didUpgrade(sessionTopic: String, permissions: Session.Permissions) {
        onSessionUpgrade?(sessionTopic, permissions)
    }
    func didUpdate(sessionTopic: String, accounts: Set<String>) {
        onSessionUpdate?(sessionTopic, accounts)
    }
    func didReceive(notification: SessionNotification, sessionTopic: String) {
        onNotificationReceived?(notification, sessionTopic)
    }
    func didUpdate(pairingTopic: String, appMetadata: AppMetadata) {
        onPairingUpdate?(pairingTopic, appMetadata)
    }
}
