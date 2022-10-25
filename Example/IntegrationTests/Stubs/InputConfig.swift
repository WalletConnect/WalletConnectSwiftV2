import Foundation

struct InputConfig {

    static var relayHost: String {
        return config(for: "RELAY_HOST")!
    }

    static var projectId: String {
        return config(for: "PROJECT_ID")!
    }

    static var defaultTimeout: TimeInterval {
        return 45
    }

    private static func config(for key: String) -> String? {
        return ProcessInfo.processInfo.environment[key]
    }
}
