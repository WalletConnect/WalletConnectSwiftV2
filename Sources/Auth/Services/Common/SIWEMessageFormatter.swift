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

struct SIWEMessage: Equatable {
    let domain: String
    let uri: String //aud
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
        if let exp = exp {
            return "\nExpiration Time: \(exp)"
        }
        return ""
    }

    var statementLine: String {
        if let statement = statement {
            return "\(statement)\n"
        }
        return ""
    }

    var nbfLine: String {
        if let nbf = nbf {
            return "\nNot Before: \(nbf)"
        }
        return ""
    }

    var requestIdLine: String {
        if let requestId = requestId {
            return "\nRequest ID: \(requestId)"
        }
        return ""
    }

    var resourcesSection: String {
        var section = ""
        if let resources = resources {
            section = "\nResources:"
            resources.forEach {
                section.append("\n- \($0)")
            }
        }
        return section
    }
}
