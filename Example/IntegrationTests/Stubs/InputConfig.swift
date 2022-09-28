import Foundation

struct InputConfig {

    static var relayHost: String {
        return config(for: "RELAY_HOST") ?? "relay.walletconnect.com"
    }

    static var projectId: String {
        return config(for: "PROJECT_ID") ?? "3ca2919724fbfa5456a25194e369a8b4"
    }

    static var defaultTimeout: TimeInterval {
        return 30
    }

    private static func config(for key: String) -> String? {
        return ProcessInfo.processInfo.environment[key]
    }
}
