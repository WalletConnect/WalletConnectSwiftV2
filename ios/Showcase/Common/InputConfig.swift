import Foundation

struct InputConfig {

    static var projectId: String {
        return config(for: "PROJECT_ID")!
    }
    
    static var relayHost: String {
        return config(for: "RELAY_HOST")!
    }

    private static func config(for key: String) -> String? {
        return Bundle.main.object(forInfoDictionaryKey: key) as? String
    }
}
