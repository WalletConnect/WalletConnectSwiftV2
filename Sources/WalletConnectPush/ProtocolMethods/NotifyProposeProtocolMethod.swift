//     

import Foundation

struct NotifyProposeProtocolMethod: ProtocolMethod {
    let method: String = "wc_pushPropose"

    let requestConfig: RelayConfig = RelayConfig(tag: 4010, prompt: true, ttl: 86400)

    let responseConfig: RelayConfig = RelayConfig(tag: 4011, prompt: true, ttl: 86400)
}

