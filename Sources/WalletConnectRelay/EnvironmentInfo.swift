#if os(iOS)
import UIKit
#endif
import Foundation

public struct ApiFlags: OptionSet {
    public let rawValue: Int
    
    public init(rawValue: Int) {
        self.rawValue = rawValue
    }
    
    public static let sign = ApiFlags(rawValue: 1 << 0)
    public static let auth = ApiFlags(rawValue: 1 << 1)
    public static let chat = ApiFlags(rawValue: 1 << 2)
    public static let push = ApiFlags(rawValue: 1 << 3)
    public static let w3w = ApiFlags(rawValue: 1 << 4)
    public static let w3i = ApiFlags(rawValue: 1 << 5)
}

public struct EnvironmentInfo {
    private static let userAgentIdentifier = "com.walletconnect.sdk.user_agent"
    private static let apiFlagsKey = "api_flags"
    private static let userAgentStorage = CodableStore<Int>(defaults: UserDefaults.standard, identifier: userAgentIdentifier)
    
    static var userAgent: String {
        "\(protocolName)/\(sdkName)\(apiFlags)/\(operatingSystem)"
    }

    static var protocolName: String {
        "wc-2"
    }

    static var sdkName: String {
        "swift-\(packageVersion)"
    }
    
    static var apiFlags: String {
        return getApiFlags().flatMap { "x\(String($0, radix: 2))" } ?? ""
    }

    static var packageVersion: String {
        let configURL = Bundle.resourceBundle.url(forResource: "PackageConfig", withExtension: "json")!
        let jsonData = try! Data(contentsOf: configURL)
        let config = try! JSONDecoder().decode(PackageConfig.self, from: jsonData)
        return config.version
    }

    static var operatingSystem: String {
#if os(iOS)
        return "\(UIDevice.current.systemName)-\(UIDevice.current.systemVersion)"
#elseif os(macOS)
        return "macOS-\(ProcessInfo.processInfo.operatingSystemVersion)"
#elseif os(tvOS)
        return "tvOS-\(ProcessInfo.processInfo.operatingSystemVersion)"
#endif
    }
    
    public static func storeApiFlags(flag: ApiFlags) {
        let apiFlagsRawValue = try? userAgentStorage.get(key: apiFlagsKey)
        var apiFlags: ApiFlags
        if let apiFlagsRawValue {
            apiFlags = ApiFlags(rawValue: apiFlagsRawValue)
        } else {
            apiFlags = []
        }
        
        apiFlags.update(with: flag)
        userAgentStorage.set(apiFlags.rawValue, forKey: apiFlagsKey)
    }
    
    public static func clearUserAgentStorage() {
        userAgentStorage.deleteAll()
    }
    
    private static func getApiFlags() -> Int? {
        guard let apiFlagsRawValue = try? userAgentStorage.get(key: apiFlagsKey) else {
            return nil
        }
        let apiFlags = ApiFlags(rawValue: apiFlagsRawValue)
        return apiFlags.rawValue
    }
}
