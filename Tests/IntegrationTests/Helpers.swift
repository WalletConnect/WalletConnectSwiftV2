
import Foundation
@testable import WalletConnect
extension WCRequest {
    
    var isPairingApprove: Bool {
        if case .pairingApprove = self.params { return true }
        return false
    }
}

extension PairingApproval {
    
    static func stub() -> PairingApproval {
        let options = RelayProtocolOptions(protocol: "", params: nil)
        let participant = Participant(publicKey: "")
        return PairingApproval(relay: options, responder: participant, expiry: 0, state: nil)
    }
}
