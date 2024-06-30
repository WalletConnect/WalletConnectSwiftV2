import Foundation

import WalletConnectSign


struct AccountDetails {
    let chain: String
    let methods: [String]
    let account: String

    var id: String {
        return "\(account)_\(chain)"
    }
}


final class SessionAccountInteractor {}
