import Foundation

public protocol SIWECacaoFormatting {
    func formatMessage(from payload: CacaoPayload) throws -> String
}

public struct SIWECacaoFormatter: SIWECacaoFormatting {

    public init() { }

    public func formatMessage(from payload: CacaoPayload) throws -> String {
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
