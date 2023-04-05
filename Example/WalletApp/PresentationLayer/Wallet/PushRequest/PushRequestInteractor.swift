import Foundation
import WalletConnectPush

final class PushRequestInteractor {
    func approve(pushRequest: PushRequest) async throws {
        try await Push.wallet.approve(id: pushRequest.id, onSign: onSing(_:))
    }
    
    func reject(pushRequest: PushRequest) async throws {
        try await Push.wallet.reject(id: pushRequest.id)
    }

    func onSing(_ message: String) async -> SigningResult {
        let privateKey = EthKeyStore.shared.privateKeyRaw
        let signer = MessageSignerFactory(signerFactory: DefaultSignerFactory()).create()
        let signature = try! signer.sign(message: message, privateKey: privateKey, type: .eip191)
        return .signed(signature)
    }
}
