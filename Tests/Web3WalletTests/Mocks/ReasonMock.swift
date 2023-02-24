import Foundation
import WalletConnectSign

struct ReasonMock: WalletConnectNetworking.Reason {
    var code: Int {
        return 0
    }

    var message: String {
        return "error"
    }
}
