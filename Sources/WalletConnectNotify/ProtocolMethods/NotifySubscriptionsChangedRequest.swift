import Foundation

struct  NotifySubscriptionsChangedProtocolMethod: ProtocolMethod {
    let method: String = "wc_notifySubscriptionsChanged"

    let requestConfig: RelayConfig = RelayConfig(tag: 4012, prompt: false, ttl: 300)

    let responseConfig: RelayConfig = RelayConfig(tag: 4013, prompt: false, ttl: 300)
}
