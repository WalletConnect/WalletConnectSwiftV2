import Foundation
@testable import WalletConnectSign

class ClientDelegate: SignClientDelegate {
    func didChangeSocketConnectionStatus(_ status: SocketConnectionStatus) {
        onConnected?()
    }

    var client: SignClient
    var onSessionSettled: ((Session) -> Void)?
    var onConnected: (() -> Void)?
    var onSessionProposal: ((Session.Proposal) -> Void)?
    var onSessionRequest: ((Request) -> Void)?
    var onSessionResponse: ((Response) -> Void)?
    var onSessionRejected: ((Session.Proposal, Reason) -> Void)?
    var onSessionDelete: (() -> Void)?
    var onSessionUpdateNamespaces: ((String, [String: SessionNamespace]) -> Void)?
    var onSessionUpdateEvents: ((String, Set<String>) -> Void)?
    var onSessionExtend: ((String, Date) -> Void)?
    var onEventReceived: ((Session.Event, String) -> Void)?
    var onPairingUpdate: ((Pairing) -> Void)?

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
    func didUpdate(sessionTopic: String, namespaces: [String: SessionNamespace]) {
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
