import Foundation

enum NotifyConfigAPI: HTTPService {

    var path: String {
        return "/w3i/v1/notify-config"
    }

    var method: HTTPMethod {
        return .get
    }

    var body: Data? {
        return nil
    }

    var queryParameters: [String : String]? {
        switch self {
        case .notifyDApps(let projectId, let appDomain):
            return ["projectId": projectId, "appDomain": appDomain]
        }
    }

    var additionalHeaderFields: [String : String]? {
        return nil
    }

    var scheme: String {
        return "https"
    }

    case notifyDApps(projectId: String, appDomain: String)
}
