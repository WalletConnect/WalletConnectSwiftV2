import Foundation

enum ChatError: Error {
    case noInviteForId
    case recordNotFound
    case userRejected
}

extension ChatError: Reason {

    var code: Int {
        // Errors not in specs yet
        return 0
    }

    var message: String {
        // Errors not in specs yet
        return localizedDescription
    }
}
