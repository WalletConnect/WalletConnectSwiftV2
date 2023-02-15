import Foundation
import WalletConnectNetworking

enum EchoAPI: HTTPService {
    case register(clientId: String, token: String, projectId: String, environment: APNSEnvironment)
    case unregister(clientId: String, projectId: String)

    var path: String {
        switch self {
        case .register(_, _, let projectId, _):
            return "/\(projectId)/clients"
        case .unregister(let clientId, let projectId):
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
        case .register(let clientId, let token, _, let environment):
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
}
