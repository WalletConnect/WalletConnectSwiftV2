import Foundation

struct InputConfig {

    static var relayHost: String {
        return ProcessInfo.processInfo.environment["RELAY_HOST"]!
    }

    static var defaultTimeout: TimeInterval {
        return 30
    }
}
