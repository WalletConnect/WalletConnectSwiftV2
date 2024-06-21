import UIKit
import WalletConnectNetworking
import Combine

final class WelcomePresenter: ObservableObject {
    private let interactor: WelcomeInteractor
    private let router: WelcomeRouter
    private var disposeBag = Set<AnyCancellable>()

    @Published var input: String = .empty

    init(interactor: WelcomeInteractor, router: WelcomeRouter) {
        defer {
            setupInitialState()
        }
        self.interactor = interactor
        self.router = router
    }
    
    func onGetStarted() {
        initSmartAccount()
        importAccount(ImportAccount.new())
    }

    func onImport() {
        guard let account = ImportAccount(input: input)
        else { return input = .empty }
        initSmartAccount()
        importAccount(account)
    }

    func initSmartAccount() {
        SmartAccount.configure(entryPoint: "", chainId: 137)
    }
}

// MARK: Private functions

private extension WelcomePresenter {

    func setupInitialState() {

    }

    func importAccount(_ importAccount: ImportAccount) {
        interactor.save(importAccount: importAccount)

        router.presentWallet(importAccount: importAccount)
    }
}

// MARK: - SceneViewModel

extension WelcomePresenter: SceneViewModel {

}
