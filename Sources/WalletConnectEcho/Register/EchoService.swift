import Foundation

enum EchoAPI: HTTPService {
    case register(clientId: String, token: String, projectId: String, environment: APNSEnvironment, auth: String)
    case unregister(clientId: String, projectId: String, auth: String)

    var path: String {
        switch self {
        case .register(_, _, let projectId, _, _):
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
        case .register(let clientId, let token, _, let environment, _):
            return try? JSONEncoder().encode([
                "client_id": clientId,
                "type": environment.rawValue,
                "token": token
            ])
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
        case .register(_, _, _, _, let auth):
            return ["Authorization": auth]
        case .unregister(_, _, let auth):
            return ["Authorization": auth]
        }
    }

}

