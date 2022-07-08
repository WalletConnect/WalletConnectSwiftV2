import Foundation

enum HTTPError: Error {
    case malformedURL(HTTPService)
    case dataTaskError(Error)
    case noResponse
    case badStatusCode(Int)
    case responseDataNil
    case jsonDecodeFailed(Error, Data)
}
