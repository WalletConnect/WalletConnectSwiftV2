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
            payload: AuthPayload(requestParams: requestParams, iat: "")
        )
    }
    
    var authRequestPublisher: AnyPublisher<AuthRequest, Never> {
        return Result.Publisher(authRequest)
            .eraseToAnyPublisher()
    }

    var authResponsePublisher: AnyPublisher<(id: RPCID, result: Result<Cacao, AuthError>), Never> {
        let cacao = Cacao(h: CacaoHeader(t: ""), p: CacaoPayload(iss: "", domain: "", aud: "", version: "", nonce: "", iat: "", nbf: "", exp: "", statement: "", requestId: "", resources: []), s: CacaoSignature(t: .eip191, s: "", m: ""))
        return Result.Publisher((RPCID(0), .success(cacao)))
            .eraseToAnyPublisher()
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
