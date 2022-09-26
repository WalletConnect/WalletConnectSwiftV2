import Foundation
import WalletConnectNetworking

struct ChatInviteProtocolMethod: ProtocolMethod {
    var method: String = "wc_chatInvite"

    var requestConfig = RelayConfig(tag: 2000, prompt: true, ttl: 86400)

    var responseConfig = RelayConfig(tag: 2001, prompt: false, ttl: 86400)

}

struct ChatMessageProtocolMethod: ProtocolMethod {
    var method: String = "wc_chatMessage"

    var requestConfig = RelayConfig(tag: 2002, prompt: true, ttl: 86400)

    var responseConfig = RelayConfig(tag: 2003, prompt: false, ttl: 86400)

}
