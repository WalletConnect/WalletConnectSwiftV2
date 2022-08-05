import Foundation

protocol SIWEMessageFormatting {
    func formatMessage(from request: AuthRequestParams) throws -> String
}

struct SIWEMessageFormatter: SIWEMessageFormatting {
    func formatMessage(from request: AuthRequestParams) throws -> String {
        fatalError("not implemented")
    }
}

struct SIWEMessage: Equatable {
    let domain: String
    let uri: String //aud
    let address: String
    let version: String
    let nonce: String
    let chainId: String
    let type: String
    let iat: String
    let nbf: String?
    let exp: String?
    let statement: String?
    let requestId: String?
    let resources: String?

    var formatted: String {
        return """
                    \(domain) wants you to sign in with your Ethereum account:\n
                    \(address)\n

                    \(statementLine)
                    URI: \(uri)\n
                    Version: \(version)\n
                    Chain ID: \(chainId)\n
                    Nonce: \(nonce)\n
                    Issued At: \(iat)\n
                    \(expLine)
                    Not Before: ${not-before}
                    Request ID: ${request-id}
                    Resources:
                    - ${resources[0]}
                    - ${resources[1]}
                    ...
                    - ${resources[n]}
                """
    }

    var expLine: String {
        if let exp = exp {
            return "Expiration Time: \(exp)\n"
        }
        return ""
    }

    var statementLine: String {
        if let statement = statement {
            return "\(statement)\n"
        }
        return ""
    }
}
