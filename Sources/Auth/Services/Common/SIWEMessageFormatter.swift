import Foundation

protocol SIWEMessageFormatting {
    func formatMessage(from request: AuthRequestParams) throws -> String
}

struct SIWEMessageFormatter: SIWEMessageFormatting {
    func formatMessage(from request: AuthRequestParams) throws -> String {
        fatalError("not implemented")
    }
}
