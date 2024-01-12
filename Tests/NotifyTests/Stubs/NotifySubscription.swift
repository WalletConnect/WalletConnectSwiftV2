import Foundation
@testable import WalletConnectNotify

extension NotifySubscription {
    static func stub(topic: String, expiry: Date) -> NotifySubscription {
        let account = Account(chainIdentifier: "eip155:1", address: "0x15bca56b6e2728aec2532df9d436bd1600e86688")!
        let relay = RelayProtocolOptions.stub()
        let metadata = AppMetadata.stub()
        let symKey = "key1"

        return NotifySubscription(
            topic: topic,
            account: account,
            relay: relay,
            metadata: metadata,
            scope: ["test": ScopeValue(id: "id", name: "name", description: "desc", imageUrls: nil, enabled: true)],
            expiry: expiry,
            symKey: symKey,
            appAuthenticationKey: "did:key:z6MkpTEGT75mnz8TiguXYYVnS1GbsNCdLo72R7kUCLShTuFV"
        )
    }
}

