
import Foundation
@testable import WalletConnect

class ClientDelegate: WalletConnectClientDelegate {
    
    var client: WalletConnectClient
    var onSessionSettled: ((Session)->())?
    var onSessionProposal: ((Session.Proposal)->())?
    var onSessionRequest: ((Request)->())?
    var onSessionResponse: ((Response)->())?
    var onSessionRejected: ((Session.Proposal, Reason)->())?
    var onSessionDelete: (()->())?
    var onSessionUpdateAccounts: ((String, Set<Account>)->())?
    var onSessionUpdateMethods: ((String, Set<String>)->())?
    var onNotificationReceived: ((Session.Event, String)->())?
    var onPairingUpdate: ((Pairing)->())?
    
    internal init(client: WalletConnectClient) {
        self.client = client
        client.delegate = self
    }
    
    func didReject(proposal: Session.Proposal, reason: Reason) {
        onSessionRejected?(proposal, reason)
    }
    func didSettle(session: Session) {
        onSessionSettled?(session)
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
    func didUpdate(sessionTopic: String, accounts: Set<Account>) {
        onSessionUpdateAccounts?(sessionTopic, accounts)
    }
    func didUpdate(sessionTopic: String, methods: Set<String>) {
        onSessionUpdateMethods?(sessionTopic, methods)
    }
    func didReceive(notification: Session.Event, sessionTopic: String) {
        onNotificationReceived?(notification, sessionTopic)
    }
    func didReceive(sessionResponse: Response) {
        onSessionResponse?(sessionResponse)
    }
}
