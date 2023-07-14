import Foundation

struct InputConfig {

    static var projectId: String {
        guard let projectId = config(for: "PROJECT_ID"), !projectId.isEmpty else {
            fatalError("PROJECT_ID is either not defined or empty in Configuration.xcconfig")
        }
        
        return projectId
    }
    
    static var relayHost: String {
        return config(for: "RELAY_HOST")!
    }

    private static func config(for key: String) -> String? {
        return Bundle.main.object(forInfoDictionaryKey: key) as? String
    }
}
