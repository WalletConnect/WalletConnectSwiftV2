import Foundation

public class SiweMessageFormatter {
    public static func format(siwe: SIWEMessage) throws -> String {
        let recapUrns = siwe.resources?.compactMap { try? RecapUrn(urn: $0)} ?? []

        let mergedRecap = try? RecapUrnMergingService.merge(recapUrns: recapUrns)     
        let statementLine = try SiweStatementBuilder.buildSiweStatement(statement: siwe.statement, mergedRecapUrn: mergedRecap)
        return """
               \(siwe.domain) wants you to sign in with your Ethereum account:
               \(siwe.address)
               \(statementLine)

               URI: \(siwe.uri)
               Version: \(siwe.version)
               Chain ID: \(siwe.chainId)
               Nonce: \(siwe.nonce)
               Issued At: \(siwe.iat)\(siwe.expLine)\(siwe.nbfLine)\(siwe.requestIdLine)\(siwe.resourcesSection)
               """
    }
}

private extension SIWEMessage {

    var expLine: String {
        guard let exp = exp else { return "" }
        return "\nExpiration Time: \(exp)"
    }

    var nbfLine: String {
        guard let nbf = nbf else { return "" }
        return "\nNot Before: \(nbf)"
    }

    var requestIdLine: String {
        guard let requestId = requestId else { return "" }
        return "\nRequest ID: \(requestId)"
    }

    var resourcesSection: String {
        guard let resources = resources else { return "" }
        let resourcesList = resources.reduce("") { $0 + "\n- \($1)" }
        return resources.isEmpty ? "" : "\nResources:" + resourcesList
    }
}
