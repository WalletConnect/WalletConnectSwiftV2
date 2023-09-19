import Foundation
import HTTPClient

enum ListingsAPI: HTTPService {

    var path: String {
        return "/w3i/v1/projects"
    }

    var method: HTTPMethod {
        return .get
    }

    var body: Data? {
        return nil
    }

    var queryParameters: [String : String]? {
        return ["projectId": InputConfig.projectId, "entries": "100", "is_verified": "false"]
    }

    var additionalHeaderFields: [String : String]? {
        return nil
    }

    var scheme: String {
        return "https"
    }

    case notifyDApps
}
