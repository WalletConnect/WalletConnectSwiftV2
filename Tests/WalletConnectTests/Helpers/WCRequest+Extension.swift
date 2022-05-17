@testable import WalletConnectAuth

extension WCRequest {

    var sessionProposal: SessionProposal? {
        guard case .sessionPropose(let proposal) = self.params else { return nil }
        return proposal
    }
}
