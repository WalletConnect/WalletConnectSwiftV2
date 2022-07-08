import Foundation
import WalletConnectUtils

struct Message: Codable, Equatable {
    var topic: String
    let message : String
    let authorAccount: Account
    let timestamp: Int64
}
