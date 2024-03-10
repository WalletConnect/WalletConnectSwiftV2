
import Foundation
import WalletConnectUtils

struct CacaosBuilder {
    public static func makeCacao(authPayload: AuthPayload, signature: WalletConnectUtils.CacaoSignature, account: WalletConnectUtils.Account) throws -> Cacao {
        let cacaoPayload = try CacaoPayloadBuilder.makeCacaoPayload(authPayload: authPayload, account: account)
        let header = CacaoHeader(t: "eip4361")
        return Cacao(h: header, p: cacaoPayload, s: signature)
    }

}

struct CacaoPayloadBuilder {
    public static func makeCacaoPayload(authPayload: AuthPayload, account: WalletConnectUtils.Account) throws -> CacaoPayload {
        let recapUrns = authPayload.resources?.compactMap { try? RecapUrn(urn: $0)} ?? []

        let mergedRecap = try? RecapUrnMergingService.merge(recapUrns: recapUrns)
        let statement = try SiweStatementBuilder.buildSiweStatement(statement: authPayload.statement, mergedRecapUrn: mergedRecap)
        return CacaoPayload(
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
    }

}
