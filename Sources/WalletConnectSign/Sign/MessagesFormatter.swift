
import Foundation
import WalletConnectUtils

struct MessagesFormatter {

    enum Errors: Error {
        case invalidChainID
    }

    public func formatMessages(payload: AuthenticationPayload, addresses: [String]) throws -> [String] {

        var messages = [String]()

        for chain in payload.chains {
            for address in addresses {

                guard
                    let blockchain = Blockchain(chain),
                    let account = Account(blockchain: blockchain, address: address) else {
                    throw Errors.invalidChainID
                }

                let cacaoPayload = CacaoPayload(
                    iss: account.did,
                    domain: payload.domain,
                    aud: payload.aud,
                    version: payload.version,
                    nonce: payload.nonce,
                    iat: payload.iat,
                    nbf: payload.nbf,
                    exp: payload.exp,
                    statement: payload.statement,
                    requestId: payload.requestId,
                    resources: payload.resources
                )

                let message = try SIWECacaoFormatter().formatMessage(from: cacaoPayload)
                messages.append(message)
            }
        }

        return messages
    }

}





