import Foundation

struct URLConfig {

    static var relayHost: String {
        return ProcessInfo.processInfo.environment["RELAY_HOST"] ?? "relay.walletconnect.com"
    }
}
