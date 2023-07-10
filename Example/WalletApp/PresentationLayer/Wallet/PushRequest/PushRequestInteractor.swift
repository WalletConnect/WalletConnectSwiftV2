import Foundation
import WalletConnectPush

final class PushRequestInteractor {
    func approve(pushRequest: PushRequest, importAccount: ImportAccount) async throws {
        try await Push.wallet.approve(id: pushRequest.id, onSign: importAccount.onSign)
    }
    
    func reject(pushRequest: PushRequest) async throws {
        try await Push.wallet.reject(id: pushRequest.id)
    }
}
