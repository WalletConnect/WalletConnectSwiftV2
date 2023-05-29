import Foundation

enum HistoryAPI: HTTPService {
    case register(payload: RegisterPayload, jwt: String)

    var path: String {
        switch self {
        case .register:
            return "/register"
        }
    }

    var method: HTTPMethod {
        switch self {
        case .register:
            return .post
        }
    }

    var body: Data? {
        switch self {
        case .register(let payload, _):
            return try? JSONEncoder().encode(payload)
        }
    }

    var additionalHeaderFields: [String : String]? {
        switch self {
        case .register(_, let jwt):
            return ["Authorization": jwt]
        }
    }

    var queryParameters: [String : String]? {
        return nil
    }
}
