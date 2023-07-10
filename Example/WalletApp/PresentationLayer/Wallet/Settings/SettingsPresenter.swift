import UIKit
import Combine
import WalletConnectNetworking

final class SettingsPresenter: ObservableObject {

    private let interactor: SettingsInteractor
    private let router: SettingsRouter
    private let accountStorage: AccountStorage
    
    private var disposeBag = Set<AnyCancellable>()

    init(interactor: SettingsInteractor, router: SettingsRouter, accountStorage: AccountStorage) {
        defer { setupInitialState() }
        self.interactor = interactor
        self.router = router
        self.accountStorage = accountStorage
    }


    var account: String {
        guard let importAccount = accountStorage.importAccount else { return .empty }
        return importAccount.account.absoluteString
    }

    var privateKey: String {
        guard let importAccount = accountStorage.importAccount else { return .empty }
        return importAccount.privateKey
    }

    var clientId: String {
        guard let clientId = try? Networking.interactor.getClientId() else { return .empty }
        return clientId
    }

    var deviceToken: String {
        guard let deviceToken = UserDefaults.standard.string(forKey: "deviceToken") else { return .empty }
        return deviceToken
    }

    func logoutPressed() {
        accountStorage.importAccount = nil
        UserDefaults.standard.set(nil, forKey: "deviceToken")
        router.presentWelcome()
    }
}

// MARK: SceneViewModel

extension SettingsPresenter: SceneViewModel {

    var sceneTitle: String? {
        return "Settings"
    }

    var largeTitleDisplayMode: UINavigationItem.LargeTitleDisplayMode {
        return .always
    }
}

// MARK: Privates

private extension SettingsPresenter {

    func setupInitialState() {

    }
}
