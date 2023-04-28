import UIKit
import WalletConnectNetworking
import Combine

final class WelcomePresenter: ObservableObject {
    private let interactor: WelcomeInteractor
    private let router: WelcomeRouter
    private var disposeBag = Set<AnyCancellable>()

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
