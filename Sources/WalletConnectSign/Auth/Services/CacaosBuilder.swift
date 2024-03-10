
import Foundation

struct CacaosBuilder {
    public func makeCacao(authPayload: AuthPayload, signature: WalletConnectUtils.CacaoSignature, account: WalletConnectUtils.Account) throws -> Cacao {
        let statement =

        let cacaoPayload = CacaoPayload(
            iss: account.did,
            domain: authPayload.domain,
            aud: authPayload.aud,
            version: authPayload.version,
            nonce: authPayload.nonce,
            iat: authPayload.iat,
            nbf: authPayload.nbf,
            exp: authPayload.exp,
            statement: statement,
            requestId: authPayload.requestId,
            resources: authPayload.resources
        )
        let header = CacaoHeader(t: "eip4361")
        return Cacao(h: header, p: cacaoPayload, s: signature)
    }

}
