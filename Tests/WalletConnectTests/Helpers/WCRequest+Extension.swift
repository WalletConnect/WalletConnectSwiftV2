@testable import WalletConnect

extension WCRequest {
    
    var sessionProposal: SessionProposal? {
        guard case .pairingPayload(let payload) = self.params else { return nil }
        return payload.request.params
    }
    
    var approveParams: SessionType.ApproveParams? {
        guard case .sessionApprove(let approveParams) = self.params else { return nil }
        return approveParams
    }
}
