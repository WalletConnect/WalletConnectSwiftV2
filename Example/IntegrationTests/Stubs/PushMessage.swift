import Foundation
import WalletConnectPush

extension PushMessage {
    static func stub() -> PushMessage {
        return PushMessage(title: "test_push_message", body: "", icon: "", url: "", type: "")
    }
}
