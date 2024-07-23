import Foundation

import WalletConnectSign


struct AccountDetails {
    let chain: String
    let methods: [String]
    let address: String
    var account: String {
        "\(chain):\(address)"
    }
}


final class SessionAccountInteractor {}
