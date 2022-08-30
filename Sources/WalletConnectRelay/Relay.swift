import Foundation

/// Relay instatnce wrapper
///
/// ```swift
/// Relay.configure(projectId: projectId,socketFactory: SocketFactory())
/// ```
public class Relay {

    /// Relay client instance
    public static var instance: RelayClient = {
        guard let config = Relay.config else {
            fatalError("Error - you must call Relay.configure(_:) before accessing the shared instance.")
        }
        return RelayClient(
            relayHost: config.relayHost,
            projectId: config.projectId,
            socketFactory: config.socketFactory,
            socketConnectionType: config.socketConnectionType
        )
    }()

    private static var config: Config?

    private init() { }

    /// Relay instance config method
    /// - Parameters:
    ///   - relayHost: relay host
    ///   - projectId: project id
    ///   - socketFactory: web socket factory
    ///   - socketConnectionType: socket connection type
    static public func configure(
        relayHost: String = "relay.walletconnect.com",
        projectId: String,
        socketFactory: WebSocketFactory,
        socketConnectionType: SocketConnectionType = .automatic
    ) {
        Relay.config = Relay.Config(
            relayHost: relayHost,
            projectId: projectId,
            socketFactory: socketFactory,
            socketConnectionType: socketConnectionType
        )
    }
}
