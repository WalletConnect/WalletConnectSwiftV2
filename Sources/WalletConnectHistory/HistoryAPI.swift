import Foundation

enum HistoryAPI: HTTPService {
    case register(payload: RegisterPayload, jwt: String)
    case messages(payload: GetMessagesPayload)

    var path: String {
        switch self {
        case .register:
            return "/register"
        case .messages:
            return "/messages"
        }
    }

    var method: HTTPMethod {
        switch self {
        case .register:
            return .post
        case .messages:
            return .get
        }
    }

    var body: Data? {
        switch self {
        case .register(let payload, _):
            return try? JSONEncoder().encode(payload)
        case .messages:
            return nil
        }
    }

    var additionalHeaderFields: [String : String]? {
        switch self {
        case .register(_, let jwt):
            return ["Authorization": "Bearer \(jwt)"]
        case .messages:
            return nil
        }
    }

    var queryParameters: [String: String]? {
        switch self {
        case .messages(let payload):
            return [
                "topic": payload.topic,
                "originId": payload.originId.map { String($0) },
                "messageCount": payload.messageCount.map { String($0) },
                "direction": payload.direction.rawValue
            ].compactMapValues { $0 }
        case .register:
            return nil
        }
    }
}
