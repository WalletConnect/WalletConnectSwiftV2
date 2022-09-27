import Foundation
import WalletConnectNetworking

struct PairingPingProtocolMethod: ProtocolMethod {
    let method: String = "wc_pairingPing"

    let requestConfig = RelayConfig(tag: 1002, prompt: false, ttl: 30)

    let responseConfig = RelayConfig(tag: 1003, prompt: false, ttl: 30)
}
