import Foundation

extension Notify {
    struct Config {
        let pushHost: String
        let groupIdentifier: String
        let environment: APNSEnvironment
        let crypto: CryptoProvider
        let notifyHost: String
    }
}
