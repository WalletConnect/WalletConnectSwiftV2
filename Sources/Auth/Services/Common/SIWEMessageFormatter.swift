import Foundation

protocol SIWEMessageFormatting {
    func formatMessage(from payload: AuthPayload, address: String) throws -> String
    func formatMessage(from payload: CacaoPayload) throws -> String
}

public struct SIWEMessageFormatter: SIWEMessageFormatting {

    enum Errors: Error {
        case invalidChainID
    }

    public init() { }

    public func formatMessage(from payload: AuthPayload, address: String) throws -> String {
        guard
            let blockchain = Blockchain(payload.chainId),
            let account = Account(blockchain: blockchain, address: address) else {
            throw Errors.invalidChainID
        }
        let payload = payload.cacaoPayload(didpkh: DIDPKH(account: account))
        return try formatMessage(from: payload)
    }

    func formatMessage(from payload: CacaoPayload) throws -> String {
        return try SIWECacaoFormatter().formatMessage(from: payload)
    }
}
