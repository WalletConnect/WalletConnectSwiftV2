import Foundation
import Auth
import WalletConnectUtils

final class AuthRequestInteractor {

    func approve(request: AuthRequest) async throws {
        let privateKey = Data(hex: "e56da0e170b5e09a8bb8f1b693392c7d56c3739a9c75740fbc558a2877868540")
        let signer = MessageSignerFactory(signerFactory: DefaultSignerFactory()).create()
        let signature = try signer.sign(message: request.message, privateKey: privateKey, type: .eip191)
        try await Auth.instance.respond(requestId: request.id, signature: signature)
    }

    func reject(request: AuthRequest) async throws {
        try await Auth.instance.reject(requestId: request.id)
    }
}
