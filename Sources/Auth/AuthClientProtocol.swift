import Foundation
import Combine

public protocol AuthClientProtocol {
    var authRequestPublisher: AnyPublisher<AuthRequest, Never> { get }
    var authResponsePublisher: AnyPublisher<(id: RPCID, result: Result<Cacao, AuthError>), Never> { get }
    
    func formatMessage(payload: AuthPayload, address: String) throws -> String
    func respond(requestId: RPCID, signature: CacaoSignature, from account: Account) async throws
    func reject(requestId: RPCID) async throws
    func getPendingRequests() throws -> [AuthRequest]
}
