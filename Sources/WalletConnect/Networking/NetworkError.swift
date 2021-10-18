enum NetworkError: Error {
    case webSocketNotConnected
    case sendMessageFailed(Error)
    case receiveMessageFailure(Error)
}

extension NetworkError {
    
    var localizedDescription: String {
        switch self {
        case .webSocketNotConnected:
            return ""
        case .sendMessageFailed(let error):
            return ""
        case .receiveMessageFailure(let error):
            return ""
        }
    }
}
