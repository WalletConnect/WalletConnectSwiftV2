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

    public var formatted: String {
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
}

private extension SIWEMessage {

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
