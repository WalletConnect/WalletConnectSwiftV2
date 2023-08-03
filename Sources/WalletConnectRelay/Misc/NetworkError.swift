import Foundation

enum NetworkError: Error, Equatable {
    case webSocketNotConnected
    case sendMessageFailed(Error)
    case receiveMessageFailure(Error)
    
    static func == (lhs: NetworkError, rhs: NetworkError) -> Bool {
        switch (lhs, rhs) {
        case (.webSocketNotConnected, .webSocketNotConnected):  return true
        case (.sendMessageFailed, .sendMessageFailed):          return true
        case (.receiveMessageFailure, .receiveMessageFailure):  return true
        default:                                                return false
        }
    }
}

extension NetworkError: LocalizedError {
    var errorDescription: String? {
        return localizedDescription
    }
    
    var localizedDescription: String {
        switch self {
        case .webSocketNotConnected:
            return "Web socket is not connected to any URL."
        case .sendMessageFailed(let error):
            return "Failed to send a message through the web socket: \(error)"
        case .receiveMessageFailure(let error):
            return "An error happened when receiving a web socket message: \(error)"
        }
    }
}
