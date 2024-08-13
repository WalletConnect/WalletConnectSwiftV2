import Foundation

enum VerifyAPI: HTTPService {
    case resolve(assertionId: String)

    var path: String {
        switch self {
        case .resolve(let assertionId):   return "/attestation/\(assertionId)"
        }
    }

    var method: HTTPMethod {
        switch self {
        case .resolve:  return .get
        }
    }

    var body: Data? {
        nil
    }

    var queryParameters: [String: String]? {
        return ["v2Supported": "true"]
    }

    var scheme: String {
        return "https"
    }

    var additionalHeaderFields: [String : String]? {
        nil
    }
}
