
import Foundation
@testable import WalletConnectAuth

class ClientDelegate: AuthClientDelegate {
    var client: AuthClient
    var onSessionSettled: ((Session)->())?
    var onConnected: (()->())?
    var onSessionProposal: ((Session.Proposal)->())?
    var onSessionRequest: ((Request)->())?
    var onSessionResponse: ((Response)->())?
    var onSessionRejected: ((Session.Proposal, Reason)->())?
    var onSessionDelete: (()->())?
    var onSessionUpdateNamespaces: ((String, [String : SessionNamespace])->())?
    var onSessionUpdateEvents: ((String, Set<String>)->())?
    var onSessionUpdateExpiry: ((String, Date)->())?
    var onEventReceived: ((Session.Event, String)->())?
    var onPairingUpdate: ((Pairing)->())?
    
    internal init(client: AuthClient) {
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
    func didUpdate(sessionTopic: String, namespaces: [String : SessionNamespace]) {
        onSessionUpdateNamespaces?(sessionTopic, namespaces)
    }
    func didUpdate(sessionTopic: String, expiry: Date) {
        onSessionUpdateExpiry?(sessionTopic, expiry)
    }
    func didReceive(event: Session.Event, sessionTopic: String, chainId: Blockchain?) {
        onEventReceived?(event, sessionTopic)
    }
    func didReceive(sessionResponse: Response) {
        onSessionResponse?(sessionResponse)
    }
    func didConnect() {
        onConnected?()
    }
    func didDisconnect() {}
}
