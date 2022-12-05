import Foundation
import WalletConnectNetworking

enum EchoAPI: HTTPService {
    case register(clientId: String, token: String, tenantId: String)
    case unregister(clientId: String, tenantId: String)

    var path: String {
        switch self {
        case .register(_, _, let tenantId):
            return "/\(tenantId)/clients"
        case .unregister(let clientId, let tenantId):
            return "/\(tenantId)/clients\(clientId)"
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
        case .register(let clientId, let token, _):
            return try? JSONEncoder().encode([
                "client_id": clientId,
                "type": "apns",
                "token": token
            ])
        case .unregister:
            return nil
        }
    }

    var queryParameters: [String : String]? {
        return nil
    }

    var scheme: String {
        return "https"
    }
}
