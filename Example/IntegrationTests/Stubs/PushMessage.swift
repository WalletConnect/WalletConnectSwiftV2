import Foundation
import WalletConnectNotify

extension NotifyMessage {
    static func stub() -> NotifyMessage {
        return NotifyMessage(
            title: "swift_test",
            body: "cad9a52d-9b0f-4aed-9cca-3e9568a079f9",
            icon: "https://images.unsplash.com/photo-1581224463294-908316338239?ixlib=rb-4.0.3&ixid=MnwxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8&auto=format&fit=crop&w=250&q=80",
            url: "https://web3inbox.com",
            type: "private")
    }
}
