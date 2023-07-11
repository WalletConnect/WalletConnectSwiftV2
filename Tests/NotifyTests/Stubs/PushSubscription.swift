
import Foundation
@testable import WalletConnectPush

extension PushSubscription {
    static func stub(topic: String, expiry: Date) -> PushSubscription {
        let account = Account(chainIdentifier: "eip155:1", address: "0x15bca56b6e2728aec2532df9d436bd1600e86688")!
        let relay = RelayProtocolOptions.stub()
        let metadata = AppMetadata.stub()
        let symKey = "key1"

        return PushSubscription(
            topic: topic,
            account: account,
            relay: relay,
            metadata: metadata,
            scope: ["test": ScopeValue(description: "desc", enabled: true)],
            expiry: expiry,
            symKey: symKey
        )
    }
}

