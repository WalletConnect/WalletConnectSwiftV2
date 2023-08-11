import Foundation
import WalletConnectChat

final class Application {
    var uri: String?
    var requestSent = false

    lazy var pushRegisterer = PushRegisterer()
    lazy var accountStorage = AccountStorage(defaults: .standard)

    lazy var messageSigner = MessageSignerFactory(signerFactory: DefaultSignerFactory()).create()
    lazy var configurationService = ConfigurationService()
}

