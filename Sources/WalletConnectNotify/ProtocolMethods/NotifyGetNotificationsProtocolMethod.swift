import Foundation

struct NotifyGetNotificationsProtocolMethod: ProtocolMethod {
    let method: String = "wc_notifyGetNotifications"

    let requestConfig: RelayConfig = RelayConfig(tag: 4014, prompt: false, ttl: 300)

    let responseConfig: RelayConfig = RelayConfig(tag: 4015, prompt: false, ttl: 300)
}
