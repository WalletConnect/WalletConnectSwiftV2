import Foundation
@testable import Auth

class SIWEMessageFormatterMock: SIWEMessageFormatting {
    var formattedMessage: String!

    func formatMessage(from authPayload: AuthPayload, address: String) throws -> String {
        return formattedMessage
    }

    func formatMessage(from payload: CacaoPayload) throws -> String {
        return formattedMessage
    }
}
