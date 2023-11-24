import Foundation

enum PushAPI: HTTPService {
    case register(clientId: String, token: String, projectId: String, environment: APNSEnvironment, auth: String, alwaysRaw: Bool)
    case unregister(clientId: String, projectId: String, auth: String)

    var path: String {
        switch self {
        case .register(_, _, let projectId, _, _, _):
            return "/\(projectId)/clients"
        case .unregister(let clientId, let projectId, _):
            return "/\(projectId)/clients\(clientId)"
        }
    }

    var method: HTTPMethod {
        switch self {
        case .register:
            return .post
        case .unregister:
            return .delete
        }
    }

    var body: Data? {
        switch self {
        case .register(let clientId, let token, _, let environment, _, let alwaysRaw):
            let request = RegisterRequest(clientId: clientId, type: environment.rawValue, token: token, alwaysRaw: alwaysRaw)
            return try? JSONEncoder().encode(request)
        case .unregister:
            return nil
        }
    }

    var queryParameters: [String: String]? {
        return nil
    }

    var scheme: String {
        return "https"
    }

    var additionalHeaderFields: [String : String]? {
        switch self {
        case .register(_, _, _, _, let auth, _):
            return ["Authorization": auth]
        case .unregister(_, _, let auth):
            return ["Authorization": auth]
        }
    }

}

struct RegisterRequest: Codable {
    let clientId: String
    let type: String
    let token: String
    let alwaysRaw: Bool

    enum CodingKeys: String, CodingKey {
        case clientId = "client_id"
        case type
        case token
        case alwaysRaw = "always_raw"
    }
}
