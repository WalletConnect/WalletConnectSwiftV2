import Foundation

import WalletConnectNetworking
import Web3Wallet

struct ThirdPartyConfigurator: Configurator {

    func configure() {
        Networking.configure(projectId: InputConfig.projectId)

        let metadata = AppMetadata(
            name: "Example Wallet",
            description: "wallet description",
            url: "example.wallet",
            icons: ["https://avatars.githubusercontent.com/u/37784886"]
        )

        Web3Wallet.configure(metadata: metadata, crypto: DefaultCryptoProvider(), environment: BuildConfiguration.shared.apnsEnvironment)
    }
}
