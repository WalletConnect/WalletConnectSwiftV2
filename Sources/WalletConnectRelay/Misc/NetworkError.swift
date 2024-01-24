import Foundation

enum NetworkError: Error, Equatable {
    case connectionFailed
    case sendMessageFailed(Error)
    case receiveMessageFailure(Error)
    
    static func == (lhs: NetworkError, rhs: NetworkError) -> Bool {
        switch (lhs, rhs) {
        case (.connectionFailed, .connectionFailed):  return true
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
        case .connectionFailed:
            return "Web socket is not connected to any URL or networking connection error"
        case .sendMessageFailed(let error):
            return "Failed to send a message through the web socket: \(error)"
        case .receiveMessageFailure(let error):
            return "An error happened when receiving a web socket message: \(error)"
        }
    }
}
