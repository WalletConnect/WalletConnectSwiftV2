import Foundation

struct InputConfig {

    static var projectId: String {
        return config(for: "PROJECT_ID") ?? "3ca2919724fbfa5456a25194e369a8b4"
    }

    private static func config(for key: String) -> String? {
        return Bundle.main.object(forInfoDictionaryKey: key) as? String
    }
}
