import Foundation
import WalletConnectUtils

protocol SIWEMessageFormatting {
    func formatMessage(from authPayload: AuthPayload, address: String) -> String?
    func formatMessage(from payload: CacaoPayload) throws -> String
}

struct SIWEMessageFormatter: SIWEMessageFormatting {
    func formatMessage(from payload: AuthPayload, address: String) -> String? {
        guard let chain = Blockchain(payload.chainId) else {return nil}
        let message = SIWEMessage(domain: payload.domain,
                    uri: payload.aud,
                    address: address,
                    version: payload.version,
                    nonce: payload.nonce,
                                  chainId: chain.reference,
                    iat: payload.iat,
                    nbf: payload.nbf,
                    exp: payload.exp,
                    statement: payload.statement,
                    requestId: payload.requestId,
                    resources: payload.resources
        )
        return message.formatted
    }

    func formatMessage(from payload: CacaoPayload) throws -> String {
        let address = try DIDPKH(iss: payload.iss).account.address
        let iss = try DIDPKH(iss: payload.iss)
        let message = SIWEMessage(
            domain: payload.domain,
            uri: payload.aud,
            address: address,
            version: payload.version,
            nonce: payload.nonce,
            chainId: iss.account.reference,
            iat: payload.iat,
            nbf: payload.nbf,
            exp: payload.exp,
            statement: payload.statement,
            requestId: payload.requestId,
            resources: payload.resources
        )
        return message.formatted
    }
}

private struct SIWEMessage: Equatable {
    let domain: String
    let uri: String // aud
    let address: String
    let version: String
    let nonce: String
    let chainId: String
    let iat: String
    let nbf: String?
    let exp: String?
    let statement: String?
    let requestId: String?
    let resources: [String]?

    var formatted: String {
        return """
                \(domain) wants you to sign in with your Ethereum account:
                \(address)
                \(statementLine)
                URI: \(uri)
                Version: \(version)
                Chain ID: \(chainId)
                Nonce: \(nonce)
                Issued At: \(iat)\(expLine)\(nbfLine)\(requestIdLine)\(resourcesSection)
                """
    }

    var expLine: String {
        guard  let exp = exp else { return "" }
        return "\nExpiration Time: \(exp)"
    }

    var statementLine: String {
        guard let statement = statement else { return "" }
        return "\n\(statement)\n"
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
        return resources.reduce("\nResources:") { $0 + "\n- \($1)" }
    }
}
