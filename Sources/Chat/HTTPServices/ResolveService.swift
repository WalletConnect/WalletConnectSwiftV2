import Foundation

struct ResolveService: HTTPService {

    let account: Account

    var path: String {
        "/resolve"
    }

    var method: HTTPMethod {
        .get
    }

    var scheme: String {
        return "https"
    }

    var body: Data? {
        nil
    }

    var queryParameters: [String: String]? {
        ["account": account.absoluteString]
    }
}
