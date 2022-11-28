import Foundation
import WalletConnectNetworking

enum EchoAPI: HTTPService {
    case register(clientId: String, token: String)
    case unregister(clientId: String)

    var path: String {
        switch self {
        case .register:
            return "/clients"
        case .unregister(let clientId):
            return "/clients\(clientId)"
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
        case .register(let clientId, let token):
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
