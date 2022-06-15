import Foundation

enum ChatError: Error {
    case noPublicKeyForInviteId
    case noInviteForId
    case recordNotFound
}
