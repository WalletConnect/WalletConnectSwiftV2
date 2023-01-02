import Foundation
import WalletConnectUtils
import WalletConnectPairing

public struct PushSubscription: Codable, Equatable {
    let topic: String
    let relay: RelayProtocolOptions
    let metadata: AppMetadata
}
