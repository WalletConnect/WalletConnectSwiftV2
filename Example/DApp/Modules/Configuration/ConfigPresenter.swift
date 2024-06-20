import UIKit
import Combine

import WalletConnectSign

final class ConfigPresenter: ObservableObject, SceneViewModel {


    private let router: ConfigRouter

    var clientId: String {
        guard let clientId = try? Networking.interactor.getClientId() else { return .empty }
        return clientId
    }

    init(
        router: ConfigRouter
    ) {
        defer { setupInitialState() }
        self.router = router
    }

    func onAppear() {

    }

    private func setupInitialState() {
        
    }

    func cleanLinkModeSupportedWalletsCache() {
        let userDefaults = UserDefaults(suiteName: Constants.groupIdentifier)!
        let prefix = "com.walletconnect.sdk.linkModeLinks"
        let keys = userDefaults.dictionaryRepresentation().keys

        for key in keys where key.hasPrefix(prefix) {
            userDefaults.removeObject(forKey: key)
        }
    }

}
