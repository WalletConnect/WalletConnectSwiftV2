import Foundation
import HTTPClient

enum ExplorerAPI: HTTPService {
    case getListings(projectId: String)

    var path: String {
        switch self {
        case .getListings: return "/w3m/v1/getiOSListings"
        }
    }

    var method: HTTPMethod {
        switch self {
        case .getListings: return .get
        }
    }

    var body: Data? {
        nil
    }

    var queryParameters: [String: String]? {
        switch self {
        case let .getListings(projectId):
            return [
                "projectId": projectId,
            ]
        }
    }

    var scheme: String {
        return "https"
    }

    var additionalHeaderFields: [String: String]? {
        nil
    }
}
