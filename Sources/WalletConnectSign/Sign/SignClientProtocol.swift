import Foundation
import Combine

public protocol SignClientProtocol {
    var sessionProposalPublisher: AnyPublisher<(proposal: Session.Proposal, context: VerifyContext?), Never> { get }
    var sessionRequestPublisher: AnyPublisher<(request: Request, context: VerifyContext?), Never> { get }
    var sessionsPublisher: AnyPublisher<[Session], Never> { get }
    var socketConnectionStatusPublisher: AnyPublisher<SocketConnectionStatus, Never> { get }
    var sessionSettlePublisher: AnyPublisher<Session, Never> { get }
    var sessionDeletePublisher: AnyPublisher<(String, Reason), Never> { get }
    var sessionResponsePublisher: AnyPublisher<Response, Never> { get }
    var sessionRejectionPublisher: AnyPublisher<(Session.Proposal, Reason), Never> { get }
    
    func connect(requiredNamespaces: [String: ProposalNamespace], optionalNamespaces: [String: ProposalNamespace]?, sessionProperties: [String: String]?, topic: String) async throws
    func request(params: Request) async throws
    func approve(proposalId: String, namespaces: [String: SessionNamespace], sessionProperties: [String: String]?) async throws
    func reject(proposalId: String, reason: RejectionReason) async throws
    func update(topic: String, namespaces: [String: SessionNamespace]) async throws
    func extend(topic: String) async throws
    func respond(topic: String, requestId: RPCID, response: RPCResult) async throws
    func emit(topic: String, event: Session.Event, chainId: Blockchain) async throws
    func pair(uri: WalletConnectURI) async throws
    func disconnect(topic: String) async throws
    func getSessions() -> [Session]
    func cleanup() async throws
    
    func getPendingRequests(topic: String?) -> [Request]
    func getSessionRequestRecord(id: RPCID) -> Request?
}
