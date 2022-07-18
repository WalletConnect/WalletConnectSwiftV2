import UIKit

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
        "2.0.0-rc.0" // HARDCODED!! Is there a runtime way to get this?
    }

    static var operatingSystem: String {
        "\(UIDevice.current.systemName)-\(UIDevice.current.systemVersion)"
    }
}
