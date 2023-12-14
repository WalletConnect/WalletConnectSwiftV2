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

    public func formatted(includeRecapInTheStatement: Bool = false) -> String {
        var finalStatement = statementLine

        if includeRecapInTheStatement,
           let resource = resources?.last,
           let decodedRecap = decodeUrnToJson(urn: resource),
            let attValue = decodedRecap["att"] {
                finalStatement += buildRecapStatement(from: attValue)
            }

        return """
               \(domain) wants you to sign in with your Ethereum account:
               \(address)
               \(finalStatement)

               URI: \(uri)
               Version: \(version)
               Chain ID: \(chainId)
               Nonce: \(nonce)
               Issued At: \(iat)\(expLine)\(nbfLine)\(requestIdLine)\(resourcesSection)
               """
    }

    

    private func decodeUrnToJson(urn: String) -> [String: [String: [String: [String]]]]? {
        // Check if the URN is in the correct format
        guard urn.starts(with: "urn:recap:") else { return nil }

        // Extract the Base64 encoded JSON part from the URN
        let base64EncodedJson = urn.replacingOccurrences(of: "urn:recap:", with: "")

        // Decode the Base64 encoded JSON
        guard let jsonData = Data(base64Encoded: base64EncodedJson) else { return nil }

        // Deserialize the JSON data into the desired dictionary
        do {
            let decodedDictionary = try JSONDecoder().decode([String: [String: [String: [String]]]].self, from: jsonData)
            return decodedDictionary
        } catch {
            return nil
        }
    }

    private func buildRecapStatement(from decodedRecap: [String: [String: [String]]]) -> String {
        var statementParts: [String] = []

        for (resourceKey, actions) in decodedRecap {
            var requestActions: [String] = []

            for (actionType, _) in actions where actionType.starts(with: "request/") {
                let action = actionType.replacingOccurrences(of: "request/", with: "")
                requestActions.append("'\(action)'")
            }

            if !requestActions.isEmpty {
                let actionsString = requestActions.joined(separator: ", ")
                statementParts.append("'\(actionsString)' for '\(resourceKey)'")
            }
        }

        if !statementParts.isEmpty {
            let formattedStatement = statementParts.joined(separator: "; ")
            return "I further authorize the stated URI to perform the following actions: (1) \(formattedStatement)."
        } else {
            return ""
        }
    }



}

private extension SIWEMessage {

    var expLine: String {
        guard  let exp = exp else { return "" }
        return "\nExpiration Time: \(exp)"
    }

    var statementLine: String {
        guard let statement = statement else { return "" }
        return "\n\(statement)"
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
