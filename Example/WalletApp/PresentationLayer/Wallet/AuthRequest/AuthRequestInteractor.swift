import Foundation
import Web3Wallet

final class AuthRequestInteractor {

    private let messageSigner: MessageSigner

    init(messageSigner: MessageSigner) {
        self.messageSigner = messageSigner
    }

    func approve(request: AuthRequest, importAccount: ImportAccount) async throws {
        let account = importAccount.account
        let signature = try messageSigner.sign(
            payload: request.payload.cacaoPayload(address: account.address),
            privateKey: Data(hex: importAccount.privateKey),
            type: .eip191)
        try await Web3Wallet.instance.respond(requestId: request.id, signature: signature, from: account)
    }

    func reject(request: AuthRequest) async throws {
        try await Web3Wallet.instance.reject(requestId: request.id)
    }

    func formatted(request: AuthRequest, account: Account) -> String {
        return try! Web3Wallet.instance.formatMessage(
            payload: request.payload,
            address: account.address
        )
    }
}
