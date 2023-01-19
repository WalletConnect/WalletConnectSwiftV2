import Foundation
import WalletConnectUtils
import WalletConnectPairing

public struct PushSubscription: Codable, Equatable {
    let topic: String
    let account: Account
    let relay: RelayProtocolOptions
    let metadata: AppMetadata
}
