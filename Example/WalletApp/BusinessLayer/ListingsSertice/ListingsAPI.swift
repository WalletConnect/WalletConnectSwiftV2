import Foundation
import HTTPClient

enum ListingsAPI: HTTPService {

    var path: String {
        return "/v3/dapps"
    }

    var method: HTTPMethod {
        return .get
    }

    var body: Data? {
        return nil
    }

    var queryParameters: [String : String]? {
        return ["projectId": InputConfig.projectId, "is_notify_enabled": "true"]
    }

    var additionalHeaderFields: [String : String]? {
        return nil
    }

    var scheme: String {
        return "https"
    }

    case notifyDApps
}
