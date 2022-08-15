import Foundation
import WalletConnectUtils
import WalletConnectRelay
import Combine

public typealias Account = WalletConnectUtils.Account
public typealias Blockchain = WalletConnectUtils.Blockchain

public class Sign {

    public static var instance: SignClient = {
        guard let config = Sign.config else {
            fatalError("Error - you must call Sign.configure(_:) before accessing the shared instance.")
        }
        return SignClientFactory.create(
            metadata: config.metadata,
            relayClient: Relay.instance
        )
    }()

    private static var config: Config?

    private init() { }

    static public func configure(
        metadata: AppMetadata,
        projectId: String,
        socketFactory: WebSocketFactory,
        socketConnectionType: SocketConnectionType = .automatic
    ) {
        Sign.config = Sign.Config(
            metadata: metadata,
            projectId: projectId,
            socketFactory: socketFactory,
            socketConnectionType: socketConnectionType
        )
        Relay.configure(
            relayHost: "relay.walletconnect.com",
            projectId: projectId,
            socketFactory: socketFactory,
            socketConnectionType: socketConnectionType
        )
    }
}
