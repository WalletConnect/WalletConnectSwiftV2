import Foundation
import WalletConnectNetworking

enum VerifyAPI: HTTPService {
    case resolve(attestationId: String)

    var path: String {
        switch self {
        case .resolve(let attestationId):   return "/attestation/\(attestationId)"
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
        return nil
    }

    var scheme: String {
        return "https"
    }

    var additionalHeaderFields: [String : String]? {
        nil
    }
}
