
import Foundation

struct CacaosProvider {
    public func makeCacao(authPayload: AuthPayload, signature: WalletConnectUtils.CacaoSignature, account: WalletConnectUtils.Account) throws -> Cacao {
        let payload = try authPayload.cacaoPayload(account: account)
        let header = CacaoHeader(t: "eip4361")
        return Cacao(h: header, p: payload, s: signature)
    }
}
