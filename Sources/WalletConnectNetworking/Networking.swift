import WalletConnectRelay
import WalletConnectUtils
import WalletConnectKMS
import Foundation

public class Networking {

    /// Networking client instance
    public static var instance: NetworkingClient {
        return Networking.interactor
    }

    public static var interactor: NetworkingInteractor = {
        guard let _ = Networking.config else {
            fatalError("Error - you must call Networking.configure(_:) before accessing the shared instance.")
        }

        return NetworkingClientFactory.create(relayClient: Relay.instance)
    }()

    public static var projectId: String {
        guard let projectId = config?.projectId else {
            fatalError("Error - you must configure projectId with Networking.configure(_:)")
        }
        return projectId
    }

    private static var config: Config?

    private init() { }

    /// Networking instance config method
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
        Networking.config = Networking.Config(
            relayHost: relayHost,
            projectId: projectId,
            socketFactory: socketFactory,
            socketConnectionType: socketConnectionType
        )
        Relay.configure(
            relayHost: relayHost,
            projectId: projectId,
            socketFactory: socketFactory,
            socketConnectionType: socketConnectionType)
    }
}
