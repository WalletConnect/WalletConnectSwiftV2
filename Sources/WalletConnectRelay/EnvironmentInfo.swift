#if os(iOS)
import UIKit
#endif
import Foundation

public enum EnvironmentInfo {

    public static var userAgent: String {
        "\(protocolName)/\(sdkName)/\(operatingSystem)"
    }

    public static var protocolName: String {
        "wc-2"
    }

    public static var sdkName: String {
        "swift-v\(packageVersion)"
    }

    public static var packageVersion: String {
        let configURL = Bundle.resourceBundle.url(forResource: "PackageConfig", withExtension: "json")!
        let jsonData = try! Data(contentsOf: configURL)
        let config = try! JSONDecoder().decode(PackageConfig.self, from: jsonData)
        return config.version
    }

    public static var operatingSystem: String {
#if os(iOS)
        return "\(UIDevice.current.systemName)-\(UIDevice.current.systemVersion)"
#elseif os(macOS)
        return "macOS-\(ProcessInfo.processInfo.operatingSystemVersion)"
#elseif os(tvOS)
        return "tvOS-\(ProcessInfo.processInfo.operatingSystemVersion)"
#endif
    }
}
