import Foundation

struct InputConfig {
    static var projectId: String {
        return config(for: "PROJECT_ID")!
    }

#if targetEnvironment(simulator)
    static var simulatorIdentifier: String {
        return config(for: "SIMULATOR_IDENTIFIER")!
    }
#endif
    
    private static func config(for key: String) -> String? {
        return Bundle.main.object(forInfoDictionaryKey: key) as? String
    }

}
