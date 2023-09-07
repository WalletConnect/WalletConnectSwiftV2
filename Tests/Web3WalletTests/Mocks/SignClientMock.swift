import Foundation
import Combine

@testable import WalletConnectSign

final class SignClientMock: SignClientProtocol {
    var approveCalled = false
    var rejectCalled = false
    var updateCalled = false
    var extendCalled = false
    var respondCalled = false
    var emitCalled = false
    var pairCalled = false
    var disconnectCalled = false
    var cleanupCalled = false
    var connectCalled = false
    var requestCalled = false
    
    private let metadata = AppMetadata(name: "", description: "", url: "", icons: [])
    private let request = WalletConnectSign.Request(id: .left(""), topic: "", method: "", params: "", chainId: Blockchain("eip155:1")!, expiry: nil)
    private let response = WalletConnectSign.Response(id: RPCID(1234567890123456789), topic: "", chainId: "", result: .response(AnyCodable(any: "")))
    
    var sessionProposalPublisher: AnyPublisher<(proposal: WalletConnectSign.Session.Proposal, context: VerifyContext?), Never> {
        let proposer = Participant(publicKey: "", metadata: metadata)
        let sessionProposal = WalletConnectSign.SessionProposal(
            relays: [],
            proposer: proposer,
            requiredNamespaces: [:],
            optionalNamespaces: nil,
            sessionProperties: nil
        ).publicRepresentation(pairingTopic: "")

        return Result.Publisher((sessionProposal, nil))
            .eraseToAnyPublisher()
    }
    
    var sessionRequestPublisher: AnyPublisher<(request: WalletConnectSign.Request, context: VerifyContext?), Never> {
        return Result.Publisher((request, nil))
            .eraseToAnyPublisher()
    }
    
    var sessionsPublisher: AnyPublisher<[WalletConnectSign.Session], Never> {
        return Result.Publisher([WalletConnectSign.Session(topic: "", pairingTopic: "", peer: metadata, requiredNamespaces: [:], namespaces: [:], sessionProperties: nil, expiryDate: Date())])
            .eraseToAnyPublisher()
    }
    
    var socketConnectionStatusPublisher: AnyPublisher<WalletConnectRelay.SocketConnectionStatus, Never> {
        return Result.Publisher(.connected)
            .eraseToAnyPublisher()
    }
    
    var sessionSettlePublisher: AnyPublisher<WalletConnectSign.Session, Never> {
        return Result.Publisher(Session(topic: "", pairingTopic: "", peer: metadata, requiredNamespaces: [:], namespaces: [:], sessionProperties: nil, expiryDate: Date()))
            .eraseToAnyPublisher()
    }
    
    var sessionDeletePublisher: AnyPublisher<(String, WalletConnectNetworking.Reason), Never> {
        return Result.Publisher(("topic", ReasonMock()))
            .eraseToAnyPublisher()
    }
    
    var sessionRejectionPublisher: AnyPublisher<(Session.Proposal, Reason), Never> {
        let sessionProposal = Session.Proposal(
            id: "",
            pairingTopic: "",
            proposer: AppMetadata(name: "", description: "", url: "", icons: []),
            requiredNamespaces: [:],
            optionalNamespaces: nil,
            sessionProperties: nil,
            proposal: SessionProposal(relays: [], proposer: Participant(publicKey: "", metadata: AppMetadata(name: "", description: "", url: "", icons: [])), requiredNamespaces: [:], optionalNamespaces: [:], sessionProperties: [:])
        )
        
        return Result.Publisher((sessionProposal, SignReasonCode.userRejectedChains))
            .eraseToAnyPublisher()
    }
    
    var sessionResponsePublisher: AnyPublisher<WalletConnectSign.Response, Never> {
        return Result.Publisher(.success(response))
            .eraseToAnyPublisher()
    }
    
    func approve(proposalId: String, namespaces: [String : WalletConnectSign.SessionNamespace], sessionProperties: [String : String]? = nil) async throws {
        approveCalled = true
    }
    
    func reject(proposalId: String, reason: WalletConnectSign.RejectionReason) async throws {
        rejectCalled = true
    }
    
    func update(topic: String, namespaces: [String : WalletConnectSign.SessionNamespace]) async throws {
        updateCalled = true
    }
    
    func extend(topic: String) async throws {
        extendCalled = true
    }
    
    func respond(topic: String, requestId: JSONRPC.RPCID, response: JSONRPC.RPCResult) async throws {
        respondCalled = true
    }
    
    func emit(topic: String, event: WalletConnectSign.Session.Event, chainId: WalletConnectUtils.Blockchain) async throws {
        emitCalled = true
    }
    
    func pair(uri: WalletConnectUtils.WalletConnectURI) async throws {
        pairCalled = true
    }
    
    func disconnect(topic: String) async throws {
        disconnectCalled = true
    }
    
    func getSessions() -> [WalletConnectSign.Session] {
        return [WalletConnectSign.Session(topic: "", pairingTopic: "", peer: metadata, requiredNamespaces: [:], namespaces: [:], sessionProperties: nil, expiryDate: Date())]
    }
    
    func getPendingProposals(topic: String?) -> [(proposal: WalletConnectSign.Session.Proposal, context: VerifyContext?)] {
        return []
    }
    
    func getPendingRequests(topic: String?) -> [(request: WalletConnectSign.Request, context: WalletConnectSign.VerifyContext?)] {
        return [(request, nil)]
    }
    
    func getSessionRequestRecord(id: JSONRPC.RPCID) -> (request: WalletConnectSign.Request, context: WalletConnectSign.VerifyContext?)? {
        return (request, nil)
    }
    
    func cleanup() async throws {
        cleanupCalled = true
    }
    
    func connect(
        requiredNamespaces: [String : WalletConnectSign.ProposalNamespace],
        optionalNamespaces: [String : WalletConnectSign.ProposalNamespace]?,
        sessionProperties: [String : String]?,
        topic: String
    ) async throws {
        connectCalled = true
    }
    
    func request(params: WalletConnectSign.Request) async throws {
        requestCalled = true
    }
}
