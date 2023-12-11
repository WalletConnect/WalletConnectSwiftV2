
import Foundation

struct CacaosProvider {
    public func makeCacao(authRequest: AuthenticationRequest, signature: WalletConnectUtils.CacaoSignature, account: WalletConnectUtils.Account) throws -> Cacao {
        let payload = try authRequest.payload.cacaoPayload(account: account)
        let header = CacaoHeader(t: "caip122")
        return Cacao(h: header, p: payload, s: signature)
    }
}
