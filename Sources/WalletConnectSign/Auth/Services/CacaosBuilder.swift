import Foundation

struct CacaosBuilder {
    public static func makeCacao(authPayload: AuthPayload, signature: CacaoSignature, account: Account) throws -> Cacao {
        let cacaoPayload = try CacaoPayloadBuilder.makeCacaoPayload(authPayload: authPayload, account: account)
        let header = CacaoHeader(t: "eip4361")
        return Cacao(h: header, p: cacaoPayload, s: signature)
    }

}

struct CacaoPayloadBuilder {
    public static func makeCacaoPayload(authPayload: AuthPayload, account: Account) throws -> CacaoPayload {
        var mergedRecap: RecapUrn?
        var resources: [String]? = nil

        if let recapUrns = authPayload.resources?.compactMap({ try? RecapUrn(urn: $0) }), !recapUrns.isEmpty {
            mergedRecap = try? RecapUrnMergingService.merge(recapUrns: recapUrns)
        }

        var statement: String? = authPayload.statement
        if let mergedRecapUrn = mergedRecap {
            statement = try SiweStatementBuilder.buildSiweStatement(statement: authPayload.statement, mergedRecapUrn: mergedRecapUrn)
        }

        // Initialize resources with the filtered list only if authPayload.resources was not nil
        if authPayload.resources != nil {
            resources = authPayload.resources?.filter { !$0.starts(with: "urn:recap:") }
            if let mergedRecapUrnString = mergedRecap?.urn {
                resources?.append(mergedRecapUrnString)
            }
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


