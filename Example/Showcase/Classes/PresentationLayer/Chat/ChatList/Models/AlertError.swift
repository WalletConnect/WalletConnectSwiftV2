import Foundation

struct AlertError: Error, LocalizedError {
    let message: String

    var errorDescription: String? {
        return message
    }
}
