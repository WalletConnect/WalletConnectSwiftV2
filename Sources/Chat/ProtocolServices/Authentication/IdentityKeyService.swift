import Foundation

enum IdentityKeyAPI: HTTPService {

    case register(cacao: String) // TODO: Cacao
    case resolve(publicKey: String)

    var path: String {
        return "/identity"
    }

    var method: WalletConnectNetworking.HTTPMethod {
        switch self {
        case .register:
            return .post
        case .resolve:
            return .get
        }
    }

    var body: Data? {
        switch self {
        case .register(let cacao):
            return try? JSONEncoder().encode(cacao)
        case .resolve:
            return nil
        }
    }

    var queryParameters: [String : String]? {
        switch self {
        case .register:
            return nil
        case .resolve(let publicKey):
            return ["publicKey": publicKey]
        }
    }
}
