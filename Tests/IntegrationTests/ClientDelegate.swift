
import Foundation
@testable import WalletConnectSign

class ClientDelegate: SignClientDelegate {
    func didChangeSocketConnectionStatus(_ status: SocketConnectionStatus) {
        onConnected?()
    }
    
    var client: SignClient
    var onSessionSettled: ((Session)->())?
    var onConnected: (()->())?
    var onSessionProposal: ((Session.Proposal)->())?
    var onSessionRequest: ((Request)->())?
    var onSessionResponse: ((Response)->())?
    var onSessionRejected: ((Session.Proposal, Reason)->())?
    var onSessionDelete: (()->())?
    var onSessionUpdateNamespaces: ((String, [String : SessionNamespace])->())?
    var onSessionUpdateEvents: ((String, Set<String>)->())?
    var onSessionExtend: ((String, Date)->())?
    var onEventReceived: ((Session.Event, String)->())?
    var onPairingUpdate: ((Pairing)->())?
    
    internal init(client: SignClient) {
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
    func didExtend(sessionTopic: String, to date: Date) {
        onSessionExtend?(sessionTopic, date)
    }
    func didReceive(event: Session.Event, sessionTopic: String, chainId: Blockchain?) {
        onEventReceived?(event, sessionTopic)
    }
    func didReceive(sessionResponse: Response) {
        onSessionResponse?(sessionResponse)
    }

    func didDisconnect() {}
}
