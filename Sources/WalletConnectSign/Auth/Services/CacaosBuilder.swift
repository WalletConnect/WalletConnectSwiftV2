
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
        var statement: String?
        if let mergedRecapUrn = mergedRecap {
            // If there's a merged recap, generate its statement
            statement = try SiweStatementBuilder.buildSiweStatement(statement: authPayload.statement, mergedRecapUrn: mergedRecapUrn)
        } else {
            // If no merged recap, use the original statement
            statement = authPayload.statement
        }

        // Filter out any resources starting with "urn:recap:", then if mergedRecap exists, add its URN as the last element
        var resources = authPayload.resources?.filter { !$0.starts(with: "urn:recap:") } ?? []
        if let mergedRecapUrn = mergedRecap {
            // Assuming RecapUrn can be converted back to its string representation
            let mergedRecapUrnString = mergedRecapUrn.urn
            resources.append(mergedRecapUrnString)
        }

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
            resources: resources
        )
    }
}
