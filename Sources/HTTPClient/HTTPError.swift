import Foundation

public enum HTTPError: Error, Equatable {
    case malformedURL(HTTPService)
    case couldNotConnect
    case dataTaskError(Error)
    case noResponse
    case badStatusCode(Int)
    case responseDataNil
    case jsonDecodeFailed(Error, Data)
    
    public static func ==(lhs: HTTPError, rhs: HTTPError) -> Bool {
        switch (lhs, rhs) {
        case (.malformedURL, .malformedURL),
             (.couldNotConnect, .couldNotConnect),
             (.noResponse, .noResponse),
             (.responseDataNil, .responseDataNil),
             (.dataTaskError, .dataTaskError),
             (.badStatusCode, .badStatusCode),
             (.jsonDecodeFailed, .jsonDecodeFailed):
            return true

        default:
            return false
        }
    }
}
