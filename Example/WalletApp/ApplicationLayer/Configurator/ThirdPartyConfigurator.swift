import Foundation

import WalletConnectNetworking
import Web3Wallet

struct ThirdPartyConfigurator: Configurator {

    func configure() {

    }

    private func configureLogging() {
        LoggingService.instance.configure()
    }
}
