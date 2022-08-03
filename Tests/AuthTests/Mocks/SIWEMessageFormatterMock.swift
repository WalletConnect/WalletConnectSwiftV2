import Foundation
@testable import Auth

class SIWEMessageFormatterMock: SIWEMessageFormatting {
    var formattedMessage: String!
    func formatMessage(from request: AuthRequestParams) throws -> String {
        return formattedMessage
    }
}
