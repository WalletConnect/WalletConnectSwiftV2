import Foundation
import WalletConnectUtils

protocol SIWEMessageFormatting {
    func formatMessage(from authPayload: AuthPayload, address: String) -> String
}

struct SIWEMessageFormatter: SIWEMessageFormatting {
    func formatMessage(from authPayload: AuthPayload, address: String) -> String {
        SIWEMessage(domain: authPayload.domain,
                    uri: authPayload.aud,
                    address: address,
                    version: authPayload.version,
                    nonce: authPayload.nonce,
                    chainId: authPayload.chainId,
                    iat: authPayload.iat,
                    nbf: authPayload.nbf,
                    exp: authPayload.exp,
                    statement: authPayload.statement,
                    requestId: authPayload.requestId,
                    resources: authPayload.resources).formatted
    }
}

private struct SIWEMessage: Equatable {
    let domain: String
    let uri: String // aud
    let address: String
    let version: Int
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
