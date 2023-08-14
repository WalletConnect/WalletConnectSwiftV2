import Foundation
import WalletConnectNotify

extension NotifyMessage {
    static func stub() -> NotifyMessage {
        return NotifyMessage(
            title: "swift_test",
            body: "gm_hourly",
            icon: "https://images.unsplash.com/photo-1581224463294-908316338239?ixlib=rb-4.0.3&ixid=MnwxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8&auto=format&fit=crop&w=250&q=80",
            url: "https://web3inbox.com",
            type: "private")
    }
}
