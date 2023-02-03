import Foundation
import WalletConnectNetworking

public class Echo {
    static public let echoHost = "echo.walletconnect.com"
    public static var instance: EchoClient = {
        guard let config = Echo.config else {
            fatalError("Error - you must call Echo.configure(_:) before accessing the shared instance.")
        }

        return EchoClientFactory.create(
            projectId: Networking.projectId,
            clientId: config.clientId,
            echoHost: config.echoHost)
    }()

    private static var config: Config?

    private init() { }

    /// Echo instance config method
    /// - Parameter clientId: https://github.com/WalletConnect/walletconnect-docs/blob/main/docs/specs/clients/core/relay/relay-client-auth.md#overview
    static public func configure(
        clientId: String,
        echoHost: String = echoHost
    ) {
        Echo.config = Echo.Config(clientId: clientId, echoHost: echoHost)
    }
}
