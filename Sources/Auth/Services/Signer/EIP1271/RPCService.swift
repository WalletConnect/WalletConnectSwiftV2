import Foundation

struct RPCService: HTTPService {
    let data: Data
    let projectId: String
    let chainId: String

    var path: String {
        return "/v1"
    }

    var method: HTTPMethod {
        return .post
    }

    var scheme: String {
        return "https"
    }

    var body: Data? {
        return data
    }

    var queryParameters: [String: String]? {
        return [
            "chainId": chainId,
            "projectId": projectId
        ]
    }
}
