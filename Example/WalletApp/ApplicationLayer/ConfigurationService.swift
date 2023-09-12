import Foundation

import Web3Inbox
import Web3Wallet

final class ConfigurationService {

    func configure(importAccount: ImportAccount) {
        Networking.configure(projectId: InputConfig.projectId, socketFactory: WalletConnectSocketClientFactory())
        Networking.instance.setLogging(level: .debug)

        let metadata = AppMetadata(
            name: "Example Wallet",
            description: "wallet description",
            url: "example.wallet",
            icons: ["https://avatars.githubusercontent.com/u/37784886"]
        )

        Web3Wallet.configure(metadata: metadata, crypto: DefaultCryptoProvider(), environment: BuildConfiguration.shared.apnsEnvironment)

        Web3Inbox.configure(
            account: importAccount.account,
            bip44: DefaultBIP44Provider(),
            config: [.chatEnabled: false, .settingsEnabled: false],
            groupIdentifier: "group.com.walletconnect.sdk",
            environment: BuildConfiguration.shared.apnsEnvironment,
            crypto: DefaultCryptoProvider(),
            onSign: importAccount.onSign
        )
        Web3Inbox.instance.setLogging(level: .debug)

        if let clientId = try? Networking.interactor.getClientId() {
            LoggingService.instance.setUpUser(account: importAccount.account.absoluteString, clientId: clientId)
            ProfilingService.instance.setUpProfiling(account: importAccount.account.absoluteString, clientId: clientId)
        }
        LoggingService.instance.startLogging()
    }
}
