import Foundation
import WalletConnectNetworking

enum AuthNetworkRequest: NetworkRequest {
    case request

    var method: String {
        return "wc_authRequest"
    }

    var tag: Int {
        return 3001
    }
}
