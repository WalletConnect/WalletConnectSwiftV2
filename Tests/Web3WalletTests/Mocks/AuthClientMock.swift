import Foundation
import Combine

@testable import Auth

final class AuthClientMock: AuthClientProtocol {
    var respondCalled = false
    var rejectCalled = false
    
    private var authRequest: AuthRequest {
        let requestParams = RequestParams(
            domain: "",
            chainId: "",
            nonce: "",
            aud: "",
            nbf: "",
            exp: "",
            statement: "",
            requestId: "",
            resources: nil
        )
        
        return AuthRequest(
            id: .left(""),
            topic: "",
            payload: AuthPayload(requestParams: requestParams, iat: "")
        )
    }
    
    var authRequestPublisher: AnyPublisher<(request: AuthRequest, context: VerifyContext?), Never> {
        return Result.Publisher((authRequest, nil)).eraseToAnyPublisher()
    }
    
    func formatMessage(payload: AuthPayload, address: String) throws -> String {
        return "formatted_message"
    }
    
    func respond(requestId: JSONRPC.RPCID, signature: CacaoSignature, from account: WalletConnectUtils.Account) async throws {
        respondCalled = true
    }
    
    func reject(requestId: JSONRPC.RPCID) async throws {
        rejectCalled = true
    }
    
    func getPendingRequests() throws -> [AuthRequest] {
        return [authRequest]
    }
}
