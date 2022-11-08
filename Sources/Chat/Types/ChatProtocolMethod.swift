import Foundation

struct ChatInviteProtocolMethod: ProtocolMethod {
    let method: String = "wc_chatInvite"

    let requestConfig = RelayConfig(tag: 2000, prompt: true, ttl: 86400)

    let responseConfig = RelayConfig(tag: 2001, prompt: false, ttl: 86400)

}

struct ChatMessageProtocolMethod: ProtocolMethod {
    let method: String = "wc_chatMessage"

    let requestConfig = RelayConfig(tag: 2002, prompt: true, ttl: 86400)

    let responseConfig = RelayConfig(tag: 2003, prompt: false, ttl: 86400)

}
