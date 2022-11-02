#if os(iOS)
import UIKit
#endif
import Foundation

enum EnvironmentInfo {

    static var userAgent: String {
        "\(protocolName)/\(sdkName)/\(operatingSystem)"
    }

    static var protocolName: String {
        "wc-2"
    }

    static var sdkName: String {
        "swift-\(sdkVersion)"
    }

    static var sdkVersion: String {
        "v1.0.4"
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
}
