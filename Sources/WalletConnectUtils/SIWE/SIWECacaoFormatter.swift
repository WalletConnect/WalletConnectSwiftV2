import Foundation

public protocol SIWECacaoFormatting {
    func formatMessage(from payload: CacaoPayload, includeRecapInTheStatement: Bool) throws -> String
}
public extension SIWECacaoFormatting {
    func formatMessage(from payload: CacaoPayload) throws -> String {
        return try formatMessage(from: payload, includeRecapInTheStatement: false)
    }
}
public struct SIWECacaoFormatter: SIWECacaoFormatting {

    public init() { }

    public func formatMessage(from payload: CacaoPayload, includeRecapInTheStatement: Bool) throws -> String {
        let iss = try DIDPKH(did: payload.iss)
        let message = SIWEMessage(
            domain: payload.domain,
            uri: payload.aud,
            address: iss.account.address,
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
        return try message.formatted()
    }
}

