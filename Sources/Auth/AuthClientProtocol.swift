import Foundation
import Combine

public protocol AuthClientProtocol {
    var authRequestPublisher: AnyPublisher<AuthRequest, Never> { get }
    
    func formatMessage(payload: AuthPayload, address: String) throws -> String
    func respond(requestId: RPCID, signature: CacaoSignature, from account: Account) async throws
    func reject(requestId: RPCID) async throws
    func getPendingRequests(account: Account) throws -> [AuthRequest]
}
