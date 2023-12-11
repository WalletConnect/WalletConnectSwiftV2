import Foundation

public class Push {
    static public let pushHost = "echo.walletconnect.com"
    public static var instance: PushClient = {
        guard let config = Push.config else {
            fatalError("Error - you must call Push.configure(_:) before accessing the shared instance.")
        }

        return PushClientFactory.create(
            projectId: Networking.projectId,
            pushHost: config.pushHost,
            groupIdentifier: Networking.groupIdentifier,
            environment: config.environment)
    }()

    private static var config: Config?

    private init() { }

    /// Push instance config method
    /// - Parameter clientId: https://github.com/WalletConnect/walletconnect-docs/blob/main/docs/specs/clients/core/relay/relay-client-auth.md#overview
    static public func configure(
        pushHost: String = pushHost,
        environment: APNSEnvironment
    ) {
        Push.config = Push.Config(pushHost: pushHost, environment: environment)
    }
}
