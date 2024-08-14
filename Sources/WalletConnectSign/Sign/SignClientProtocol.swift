import Foundation
import Combine

public protocol SignClientProtocol {
    var logger: ConsoleLogging { get }
    var sessionProposalPublisher: AnyPublisher<(proposal: Session.Proposal, context: VerifyContext?), Never> { get }
    var sessionRequestPublisher: AnyPublisher<(request: Request, context: VerifyContext?), Never> { get }
    var sessionsPublisher: AnyPublisher<[Session], Never> { get }
    var socketConnectionStatusPublisher: AnyPublisher<SocketConnectionStatus, Never> { get }
    var sessionSettlePublisher: AnyPublisher<Session, Never> { get }
    var sessionDeletePublisher: AnyPublisher<(String, Reason), Never> { get }
    var sessionResponsePublisher: AnyPublisher<Response, Never> { get }
    var sessionRejectionPublisher: AnyPublisher<(Session.Proposal, Reason), Never> { get }
    var sessionEventPublisher: AnyPublisher<(event: Session.Event, sessionTopic: String, chainId: Blockchain?), Never> { get }
    var authenticateRequestPublisher: AnyPublisher<(request: AuthenticationRequest, context: VerifyContext?), Never> { get }
    var logsPublisher: AnyPublisher<Log, Never> {get}
    var sessionProposalExpirationPublisher: AnyPublisher<Session.Proposal, Never> { get }
    var pendingProposalsPublisher: AnyPublisher<[(proposal: Session.Proposal, context: VerifyContext?)], Never> { get }
    var requestExpirationPublisher: AnyPublisher<RPCID, Never> { get }

    func request(params: Request) async throws
    func approve(proposalId: String, namespaces: [String: SessionNamespace], sessionProperties: [String: String]?) async throws -> Session
    func authenticate(_ params: AuthRequestParams, walletUniversalLink: String?) async throws -> WalletConnectURI?
    func rejectSession(proposalId: String, reason: RejectionReason) async throws
    func rejectSession(requestId: RPCID) async throws
    func update(topic: String, namespaces: [String: SessionNamespace]) async throws
    func extend(topic: String) async throws
    func approveSessionAuthenticate(requestId: RPCID, auths: [AuthObject]) async throws -> Session?
    func buildSignedAuthObject(authPayload: AuthPayload, signature: CacaoSignature, account: Account) throws -> AuthObject
    func respond(topic: String, requestId: RPCID, response: RPCResult) async throws
    func emit(topic: String, event: Session.Event, chainId: Blockchain) async throws
    func disconnect(topic: String) async throws
    func getSessions() -> [Session]
    func formatAuthMessage(payload: AuthPayload, account: Account) throws -> String
    func buildAuthPayload(payload: AuthPayload, supportedEVMChains: [Blockchain], supportedMethods: [String]) throws -> AuthPayload 
    func dispatchEnvelope(_ envelope: String) throws
    func cleanup() async throws
    
    func getPendingRequests(topic: String?) -> [(request: Request, context: VerifyContext?)]
    func getPendingAuthRequests() throws -> [(AuthenticationRequest, VerifyContext?)]
    func getPendingProposals(topic: String?) -> [(proposal: Session.Proposal, context: VerifyContext?)]
}

