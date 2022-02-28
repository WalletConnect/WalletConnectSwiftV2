@testable import WalletConnect

extension WCRequest {

    var approveParams: SessionType.ApproveParams? {
        guard case .sessionApprove(let approveParams) = self.params else { return nil }
        return approveParams
    }
    
    var sessionProposal: SessionProposal? {
        guard case .sessionPropose(let proposal) = self.params else { return nil }
        return payload.request.params
    }
}
