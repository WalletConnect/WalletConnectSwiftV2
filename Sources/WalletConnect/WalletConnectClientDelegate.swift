
import Foundation

/// A protocol that defines methods that WalletConnectClient instance call on it's delegate to handle sequences level events
public protocol WalletConnectClientDelegate: AnyObject {
    
    /// Tells the delegate that session proposal has been received.
    ///
    /// Function is executed on responder client only
    func didReceive(sessionProposal: Session.Proposal)
    
    /// Tells the delegate that session payload request has been received
    ///
    /// In most cases that function is supposed to be called on wallet client.
    /// - Parameters:
    ///     - sessionRequest: Object containing request received from peer client.
    func didReceive(sessionRequest: Request)
    
    /// Tells the delegate that session payload response has been received
    ///
    /// In most cases that function is supposed to be called on dApp client.
    /// - Parameters:
    ///     - sessionResponse: Object containing response received from peer client.
    func didReceive(sessionResponse: Response)
    
    /// Tells the delegate that the peer client has terminated the session.
    ///
    /// Function can be executed on any type of the client.
    func didDelete(sessionTopic: String, reason: Reason)
    
    /// Tells the delegate that accounts has been updated in session
    ///
    /// Function is executed on controller and non-controller client when both communicating peers have successfully updated accounts requested by the controller client.
    func didUpdate(sessionTopic: String, accounts: Set<Account>)
    
    /// Tells the delegate that methods has been updated in session
    ///
    /// Function is executed on controller and non-controller client when both communicating peers have successfully updated methods requested by the controller client.
    func didUpdate(sessionTopic: String, namespaces: Set<Namespace>)
    
    /// Tells the delegate that session expiry has been updated
    ///
    /// Function will be executed on controller and non-controller clients.
    func didUpdate(sessionTopic: String, expiry: Date)

    /// Tells the delegate that the client has settled a session.
    ///
    /// Function is executed on proposer and responder client when both communicating peers have successfully established a session.
    func didSettle(session: Session)
    
    /// Tells the delegate that event has been received.
    func didReceive(event: Session.Event, sessionTopic: String, chainId: Blockchain?)
    
    /// Tells the delegate that peer client has rejected a session proposal.
    ///
    /// Function will be executed on proposer client only.
    func didReject(proposal: Session.Proposal, reason: Reason)
    
    /// Tells the delegate that client has connected WebSocket
    func didConnect()
}

public extension WalletConnectClientDelegate {
    func didReceive(event: Session.Event, sessionTopic: String, chainId: Blockchain?) {}
    func didReject(proposal: Session.Proposal, reason: Reason) {}
    func didReceive(sessionRequest: Request) {}
    func didReceive(sessionProposal: Session.Proposal) {}
    func didReceive(sessionResponse: Response) {}
    func didUpdate(sessionTopic: String, expiry: Date) {}
}
