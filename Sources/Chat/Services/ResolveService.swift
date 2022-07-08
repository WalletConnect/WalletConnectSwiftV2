import Foundation
import WalletConnectRelay
import WalletConnectUtils

struct ResolveService: HTTPService {

    let account: Account

    var path: String {
        "/resolve"
    }

    var method: HTTPMethod {
        .get
    }

    var body: Data? {
        nil
    }

    var queryParameters: [String: String]? {
        ["account": account.absoluteString]
    }
}
