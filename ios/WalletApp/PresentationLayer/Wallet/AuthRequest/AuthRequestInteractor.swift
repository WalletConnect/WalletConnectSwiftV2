import Foundation
import Web3Wallet

final class AuthRequestInteractor {
    private let signer = MessageSignerFactory(signerFactory: DefaultSignerFactory()).create()
    private var account: Account {
        Account(blockchain: Blockchain("eip155:1")!, address: EthKeyStore.shared.address)!
    }

    func approve(request: AuthRequest) async throws {
        let privateKey = EthKeyStore.shared.privateKeyRaw
        let signature = try signer.sign(
            payload: request.payload.cacaoPayload(address: account.address),
            privateKey: privateKey,
            type: .eip191)
        try await Web3Wallet.instance.respond(requestId: request.id, signature: signature, from: account)
    }

    func reject(request: AuthRequest) async throws {
        try await Web3Wallet.instance.reject(requestId: request.id)
    }

    func formatted(request: AuthRequest) -> String {
        return try! Web3Wallet.instance.formatMessage(
            payload: request.payload,
            address: account.address
        )
    }
}
