import Foundation

import Web3Inbox

final class ConfigurationService {

    func configure(importAccount: ImportAccount) {
        Web3Inbox.configure(
            account: importAccount.account,
            bip44: DefaultBIP44Provider(),
            config: [.chatEnabled: false, .settingsEnabled: false],
            environment: BuildConfiguration.shared.apnsEnvironment,
            onSign: importAccount.onSign
        )
    }
}
