import Foundation
import WalletConnectPush

class BuildConfiguration {
    enum Environment: String {
        case debug = "Debug"
        case release = "Release"
    }

    static let shared = BuildConfiguration()

    var environment: Environment

    var apnsEnvironment: APNSEnvironment {
        switch environment {
        case .debug:
            return .sandbox
        case .release:
            return .production
        }
    }

    init() {
        let currentConfiguration = Bundle.main.object(forInfoDictionaryKey: "CONFIGURATION") as! String
        environment = Environment(rawValue: currentConfiguration)!
    }
}
