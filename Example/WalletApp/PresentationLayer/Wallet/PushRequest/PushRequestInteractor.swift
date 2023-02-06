import Foundation
import WalletConnectPush

final class PushRequestInteractor {
    func approve(pushRequest: PushRequest) async throws {
        try await Push.wallet.approve(id: pushRequest.id)        
    }
    
    func reject(pushRequest: PushRequest) async throws {
        try await Push.wallet.reject(id: pushRequest.id)
    }
}
