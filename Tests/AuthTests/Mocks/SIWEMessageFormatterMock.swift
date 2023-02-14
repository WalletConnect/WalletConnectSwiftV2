import Foundation
@testable import Auth

class SIWEMessageFormatterMock: SIWECacaoFormatting {
    var formattedMessage: String!

    func formatMessage(from payload: CacaoPayload) throws -> String {
        return formattedMessage
    }
}
