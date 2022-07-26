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
        "v0.9.1-rc.0"
    }

    static var operatingSystem: String {
        "\(UIDevice.current.systemName)-\(UIDevice.current.systemVersion)"
    }
}
