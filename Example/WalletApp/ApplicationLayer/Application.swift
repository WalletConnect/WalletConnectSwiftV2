import Foundation
import WalletConnectUtils
import WalletConnectSigner

final class Application {
    var uri: WalletConnectURI?
    var requestSent = false

    lazy var pushRegisterer = PushRegisterer()
    lazy var accountStorage = AccountStorage(defaults: .standard)

    lazy var messageSigner = MessageSignerFactory(signerFactory: DefaultSignerFactory()).create()
    lazy var configurationService = ConfigurationService()
}
