import Foundation

struct InputConfig {
    static var projectId: String {
        return config(for: "PROJECT_ID")!
    }
    
    private static func config(for key: String) -> String? {
        return Bundle.main.object(forInfoDictionaryKey: key) as? String
    }

}
