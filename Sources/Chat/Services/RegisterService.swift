import Foundation
import WalletConnectRelay

struct RegisterService: HTTPService {

    let userAccount: UserAccount

    var path: String {
        "/register"
    }

    var method: HTTPMethod {
        .post
    }

    var body: Data? {
        try? JSONEncoder().encode(userAccount)
    }

    var queryParameters: [String : String]? {
        nil
    }
}
