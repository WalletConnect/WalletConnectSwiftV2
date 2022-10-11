import Foundation
import WalletConnectRelay

struct RPCService: HTTPService {
    let data: Data
    let projectId: String

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

    var queryParameters: [String : String]? {
        return [
            "chainId": "eip155:1",
            "projectId": projectId
        ]
    }
}
