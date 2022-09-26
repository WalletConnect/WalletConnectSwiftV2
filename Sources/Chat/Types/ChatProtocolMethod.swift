import Foundation
import WalletConnectNetworking

struct ChatInviteProtocolMethod: ProtocolMethod {
    var method: String = "wc_chatInvite"

    var request = RelayConfigrable(tag: 2000, prompt: true)

    var response = RelayConfigrable(tag: 2001, prompt: false)

}

struct ChatMessageProtocolMethod: ProtocolMethod {
    var method: String = "wc_chatMessage"

    var request = RelayConfigrable(tag: 2002, prompt: true)

    var response = RelayConfigrable(tag: 2003, prompt: false)

}
