import Foundation
@testable import WalletConnect

let defaultTimeout: TimeInterval = 5.0

extension String {
    static func randomTopic() -> String {
        "\(UUID().uuidString)\(UUID().uuidString)".replacingOccurrences(of: "-", with: "").lowercased()
    }
}

extension Result {
    
    var isSuccess: Bool {
        if case .success = self { return true }
        return false
    }
    
    var isFailure: Bool {
        if case .failure = self { return true }
        return false
    }
}

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
