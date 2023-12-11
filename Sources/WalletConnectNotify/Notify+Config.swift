import Foundation

extension Notify {
    struct Config {
        let pushHost: String
        let environment: APNSEnvironment
        let crypto: CryptoProvider
        let notifyHost: String
        let explorerHost: String
    }
}
