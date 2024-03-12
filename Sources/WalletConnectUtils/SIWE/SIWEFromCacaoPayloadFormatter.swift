import Foundation

public protocol SIWEFromCacaoFormatting {
    func formatMessage(from payload: CacaoPayload, includeRecapInTheStatement: Bool) throws -> String
}
public extension SIWEFromCacaoFormatting {
    func formatMessage(from payload: CacaoPayload) throws -> String {
        return try formatMessage(from: payload, includeRecapInTheStatement: true)
    }
}


public struct SIWEFromCacaoPayloadFormatter: SIWEFromCacaoFormatting {

    public init() {}

    public func formatMessage(from payload: CacaoPayload, includeRecapInTheStatement: Bool) throws -> String {
        let iss = try DIDPKH(did: payload.iss)
        let address = iss.account.address
        let chainId = iss.account.reference

        // Directly use the statement from payload, add a newline if it exists
        let statementLine = payload.statement.flatMap { "\n\($0)" } ?? ""

        // Format the message with all details
        let formattedMessage = """
        \(payload.domain) wants you to sign in with your Ethereum account:
        \(address)
        \(statementLine)

        URI: \(payload.aud)
        Version: \(payload.version)
        Chain ID: \(chainId)
        Nonce: \(payload.nonce)
        Issued At: \(payload.iat)\(formatExpLine(exp: payload.exp))\(formatNbfLine(nbf: payload.nbf))\(formatRequestIdLine(requestId: payload.requestId))\(formatResourcesSection(resources: payload.resources))
        """
        return formattedMessage
    }

    // Helper methods for formatting individual parts of the message
    private func formatExpLine(exp: String?) -> String {
        guard let exp = exp else { return "" }
        return "\nExpiration Time: \(exp)"
    }

    private func formatNbfLine(nbf: String?) -> String {
        guard let nbf = nbf else { return "" }
        return "\nNot Before: \(nbf)"
    }

    private func formatRequestIdLine(requestId: String?) -> String {
        guard let requestId = requestId else { return "" }
        return "\nRequest ID: \(requestId)"
    }

    private func formatResourcesSection(resources: [String]?) -> String {
        guard let resources = resources else { return "" }
        let resourcesList = resources.reduce("") { $0 + "\n- \($1)" }
        return resources.isEmpty ? "\nResources:" : "\nResources:" + resourcesList
    }
}
