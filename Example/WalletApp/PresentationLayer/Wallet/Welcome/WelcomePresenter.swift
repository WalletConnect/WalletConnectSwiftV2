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
        let pasteboard = UIPasteboard.general
        let clientId = try? Networking.interactor.getClientId()
        pasteboard.string = clientId
        interactor.saveAccount(ImportAccount.new())
        router.presentWallet()
    }

    func onImport() {
        guard let account = ImportAccount(input: input)
        else { return input = .empty }
        interactor.saveAccount(account)
        router.presentWallet()
    }
}

// MARK: Private functions
extension WelcomePresenter {
    private func setupInitialState() {

    }
}

// MARK: - SceneViewModel
extension WelcomePresenter: SceneViewModel {

}
