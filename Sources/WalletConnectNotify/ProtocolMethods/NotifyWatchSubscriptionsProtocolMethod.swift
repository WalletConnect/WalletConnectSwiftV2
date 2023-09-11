import Foundation

struct NotifyWatchSubscriptionsProtocolMethod: ProtocolMethod {
    let method: String = "wc_notifyWatchSubscriptions"

    let requestConfig: RelayConfig = RelayConfig(tag: 4010, prompt: false, ttl: 300)

    let responseConfig: RelayConfig = RelayConfig(tag: 4011, prompt: false, ttl: 300)
}
