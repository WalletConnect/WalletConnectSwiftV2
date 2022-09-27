import Foundation

struct InputConfig {

    static var relayHost: String {
        return ProcessInfo.processInfo.environment["RELAY_HOST"]!
    }

    static var walletID: String {
        return "3ca2919724fbfa5456a25194e369a8b4"
    }

    static var appID: String {
        return "e42c15f0391c158e0e84e61cbf317b7f"
    }
}
