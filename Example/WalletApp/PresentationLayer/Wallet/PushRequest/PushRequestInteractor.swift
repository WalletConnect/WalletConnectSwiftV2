import Foundation
import WalletConnectPush

final class PushRequestInteractor {
    func approve(pushRequest: PushRequest) async throws {
        try await Push.wallet.approve(id: pushRequest.id, onSign: onSign)
    }
    
    func reject(pushRequest: PushRequest) async throws {
        try await Push.wallet.reject(id: pushRequest.id)
    }

    private func onSing(_ message: String) -> SigningResult {
        let privateKey = Data(hex: "e56da0e170b5e09a8bb8f1b693392c7d56c3739a9c75740fbc558a2877868540")
        let signer = MessageSignerFactory(signerFactory: DefaultSignerFactory()).create()
        let signature = try! signer.sign(message: message, privateKey: privateKey, type: .eip191)
        return .signed(signature)
    }
}
