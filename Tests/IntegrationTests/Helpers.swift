
import Foundation
@testable import WalletConnect
extension WCRequest {
    
    var isPairingApprove: Bool {
        if case .pairingApprove = self.params { return true }
        return false
    }
}

extension PairingType.ApproveParams {
    
    static func stub() -> PairingType.ApproveParams {
        let options = RelayProtocolOptions(protocol: "", params: nil)
        let participant = PairingType.Participant(publicKey: "")
        return PairingType.ApproveParams(relay: options, responder: participant, expiry: 0, state: nil)
    }
}
