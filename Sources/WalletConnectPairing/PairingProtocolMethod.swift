import Foundation
import WalletConnectNetworking

enum PairingProtocolMethod: String, ProtocolMethod {
    case ping = "wc_pairingPing"

    var method: String {
        return self.rawValue
    }

    var requestTag: Int {
        return 1002
    }

    var responseTag: Int {
        return 1003
    }
}
