import UIKit
import WalletConnectNetworking
import WalletConnectNotify
import Web3Wallet

final class ConfigurationService {

    func configure(importAccount: ImportAccount) {
        Networking.configure(projectId: InputConfig.projectId, socketFactory: DefaultSocketFactory())
        Networking.instance.setLogging(level: .debug)

        let metadata = AppMetadata(
            name: "Example Wallet",
            description: "wallet description",
            url: "example.wallet",
            icons: ["https://avatars.githubusercontent.com/u/37784886"]
        )

        Web3Wallet.configure(metadata: metadata, crypto: DefaultCryptoProvider(), environment: BuildConfiguration.shared.apnsEnvironment)

        Notify.configure(
            groupIdentifier: "group.com.walletconnect.sdk",
            environment: BuildConfiguration.shared.apnsEnvironment,
            crypto: DefaultCryptoProvider()
        )

        Notify.instance.setLogging(level: .debug)

        if let clientId = try? Networking.interactor.getClientId() {
            LoggingService.instance.setUpUser(account: importAccount.account.absoluteString, clientId: clientId)
            ProfilingService.instance.setUpProfiling(account: importAccount.account.absoluteString, clientId: clientId)
        }
        LoggingService.instance.startLogging()

        Task {
            do {
                try await Notify.instance.register(account: importAccount.account, domain: "com.walletconnect", onSign: importAccount.onSign)
            } catch {
                DispatchQueue.main.async {
                    let logMessage = LogMessage(message: "Push Server registration failed with: \(error.localizedDescription)")
                    ProfilingService.instance.send(logMessage: logMessage)
                    UIApplication.currentWindow.rootViewController?.showAlert(title: "Register error", error: error)
                }
            }
        }
    }
}
