import UIKit
import Combine
import Auth

final class WelcomePresenter: ObservableObject {

    private let router: WelcomeRouter
    private let interactor: WelcomeInteractor

    private var disposeBag = Set<AnyCancellable>()

    init(router: WelcomeRouter, interactor: WelcomeInteractor) {
        defer { setupInitialState() }
        self.router = router
        self.interactor = interactor
    }

    var buttonTitle: String {
        return interactor.isAuthorized() ? "Start Messaging" : "Connect wallet"
    }

    @MainActor
    func didPressImport() async {
        if let account = interactor.importAccount?.account {
            await interactor.goPublic()
            router.presentMain(account: account)
        } else {
            router.presentImport()
        }
    }
}

private extension WelcomePresenter {

    func setupInitialState() {
        
    }
}
