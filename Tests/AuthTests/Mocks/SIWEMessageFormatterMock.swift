import Foundation
@testable import Auth

class SIWEMessageFormatterMock: SIWECacaoFormatting {
    func formatMessage(from payload: WalletConnectUtils.CacaoPayload) throws -> String {
        fatalError()
    }
    
    var formattedMessage: String!

    func formatMessages(from payload: CacaoPayload) throws -> String {
        return formattedMessage
    }
}
