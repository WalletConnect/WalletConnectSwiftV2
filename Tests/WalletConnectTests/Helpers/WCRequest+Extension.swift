@testable import WalletConnect

extension WCRequest {

    var approveParams: SessionType.ApproveParams? {
        guard case .sessionApprove(let approveParams) = self.params else { return nil }
        return approveParams
    }
}
