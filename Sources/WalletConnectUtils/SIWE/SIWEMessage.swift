import Foundation

public struct SIWEMessage: Equatable {
    public let domain: String
    public let uri: String // aud
    public let address: String
    public let version: String
    public let nonce: String
    public let chainId: String
    public let iat: String
    public let nbf: String?
    public let exp: String?
    public let statement: String?
    public let requestId: String?
    public let resources: [String]?

    public init(domain: String, uri: String, address: String, version: String, nonce: String, chainId: String, iat: String, nbf: String?, exp: String?, statement: String?, requestId: String?, resources: [String]?) {
        self.domain = domain
        self.uri = uri
        self.address = address
        self.version = version
        self.nonce = nonce
        self.chainId = chainId
        self.iat = iat
        self.nbf = nbf
        self.exp = exp
        self.statement = statement
        self.requestId = requestId
        self.resources = resources
    }
}

import Foundation

public class SiweMessageFormatter {
    public static func format(_ message: SIWEMessage) throws -> String {
        let statementLine = try getStatementLine(for: message)
        return """
               \(message.domain) wants you to sign in with your Ethereum account:
               \(message.address)
               \(statementLine)

               URI: \(message.uri)
               Version: \(message.version)
               Chain ID: \(message.chainId)
               Nonce: \(message.nonce)
               Issued At: \(message.iat)\(getExpLine(for: message))\(getNbfLine(for: message))\(getRequestIdLine(for: message))\(getResourcesSection(for: message))
               """
    }

    private static func getStatementLine(for message: SIWEMessage) throws -> String {
        if let recaps = message.resources?.compactMap({ try? RecapUrn(urn: $0) }),
           let mergedRecap = try? RecapUrnMergingService.merge(recapUrns: recaps) {
            do {
                let recapStatement = try RecapStatementBuilder.buildRecapStatement(recapUrn: mergedRecap)
                if let statement = message.statement {
                    return "\n\(statement) \(recapStatement)"
                } else {
                    return "\n\(recapStatement)"
                }
            } catch {
                throw error
            }
        } else {
            guard let statement = message.statement else { return "" }
            return "\n\(statement)"
        }
    }

    private static func getExpLine(for message: SIWEMessage) -> String {
        guard let exp = message.exp else { return "" }
        return "\nExpiration Time: \(exp)"
    }

    private static func getNbfLine(for message: SIWEMessage) -> String {
        guard let nbf = message.nbf else { return "" }
        return "\nNot Before: \(nbf)"
    }

    private static func getRequestIdLine(for message: SIWEMessage) -> String {
        guard let requestId = message.requestId else { return "" }
        return "\nRequest ID: \(requestId)"
    }

    private static func getResourcesSection(for message: SIWEMessage) -> String {
        guard let resources = message.resources else { return "" }
        return resources.reduce("\nResources:") { $0 + "\n- \($1)" }
    }
}
