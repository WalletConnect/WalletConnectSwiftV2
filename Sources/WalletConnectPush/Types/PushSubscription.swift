
import Foundation
import WalletConnectUtils
import WalletConnectPairing

public struct PushSubscription: Codable {
    let topic: String
     let relay: RelayProtocolOptions
     let metadata: AppMetadata
     let acknowledged: Bool
}
