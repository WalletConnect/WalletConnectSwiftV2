import Foundation
import Auth
import WalletConnectUtils

final class AuthRequestInteractor {
    private let signer = MessageSignerFactory(signerFactory: DefaultSignerFactory()).create()
    private let account = Account("eip155:1:0xe5EeF1368781911d265fDB6946613dA61915a501")!

    func approve(request: AuthRequest) async throws {
        let privateKey = Data(hex: "e56da0e170b5e09a8bb8f1b693392c7d56c3739a9c75740fbc558a2877868540")
        let signature = try signer.sign(
            payload: request.payload,
            address: account.address,
            privateKey: privateKey,
            type: .eip191)
        try await Auth.instance.respond(requestId: request.id, signature: signature, from: account)
    }

    func reject(request: AuthRequest) async throws {
        try await Auth.instance.reject(requestId: request.id)
    }

    func formatted(request: AuthRequest) -> String {
        return try! Auth.instance.formatMessage(
            payload: request.payload,
            address: account.address
        )
    }
}
