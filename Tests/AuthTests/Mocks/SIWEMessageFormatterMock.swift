import Foundation
@testable import Auth

class SIWEMessageFormatterMock: SIWECacaoFormatting {
    var formattedMessage: String!

    func formatMessages(from payload: CacaoPayload) throws -> String {
        return formattedMessage
    }
}
