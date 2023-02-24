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
    
    private let metadata = AppMetadata(name: "", description: "", url: "", icons: [])
    private let request = WalletConnectSign.Request(id: .left(""), topic: "", method: "", params: "", chainId: Blockchain("eip155:1")!, expiry: nil)
    private let response = WalletConnectSign.Response(id: RPCID(1234567890123456789), topic: "", chainId: "", result: .response(AnyCodable(any: "")))
    
    var sessionProposalPublisher: AnyPublisher<WalletConnectSign.Session.Proposal, Never> {
        let proposer = Participant(publicKey: "", metadata: metadata)
        let sessionProposal = WalletConnectSign.SessionProposal(
            relays: [],
            proposer: proposer,
            requiredNamespaces: [:],
            optionalNamespaces: nil,
            sessionProperties: nil
        ).publicRepresentation(pairingTopic: "")

        return Result.Publisher(sessionProposal)
            .eraseToAnyPublisher()
    }
    
    var sessionRequestPublisher: AnyPublisher<WalletConnectSign.Request, Never> {
        return Result.Publisher(request)
            .eraseToAnyPublisher()
    }
    
    var sessionsPublisher: AnyPublisher<[WalletConnectSign.Session], Never> {
        return Result.Publisher([WalletConnectSign.Session(topic: "", pairingTopic: "", peer: metadata, namespaces: [:], expiryDate: Date())])
            .eraseToAnyPublisher()
    }
    
    var socketConnectionStatusPublisher: AnyPublisher<WalletConnectRelay.SocketConnectionStatus, Never> {
        return Result.Publisher(.connected)
            .eraseToAnyPublisher()
    }
    
    var sessionSettlePublisher: AnyPublisher<WalletConnectSign.Session, Never> {
        return Result.Publisher(Session(topic: "", pairingTopic: "", peer: metadata, namespaces: [:], expiryDate: Date()))
            .eraseToAnyPublisher()
    }
    
    var sessionDeletePublisher: AnyPublisher<(String, WalletConnectNetworking.Reason), Never> {
        return Result.Publisher(("topic", ReasonMock()))
            .eraseToAnyPublisher()
    }
    
    var sessionResponsePublisher: AnyPublisher<WalletConnectSign.Response, Never> {
        return Result.Publisher(.success(response))
            .eraseToAnyPublisher()
    }
    
    func approve(proposalId: String, namespaces: [String : WalletConnectSign.SessionNamespace]) async throws {
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
        return [WalletConnectSign.Session(topic: "", pairingTopic: "", peer: metadata, namespaces: [:], expiryDate: Date())]
    }
    
    func getPendingRequests(topic: String?) -> [WalletConnectSign.Request] {
        return [request]
    }
    
    func getSessionRequestRecord(id: JSONRPC.RPCID) -> WalletConnectSign.Request? {
        return request
    }
    
    func cleanup() async throws {
        cleanupCalled = true
    }
}
