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
    func didPressImport() async throws {
        if let importAccount = interactor.importAccount {
            try await interactor.goPublic()
            router.presentMain(importAccount: importAccount)
        } else {
            router.presentImport()
        }
    }
}

private extension WelcomePresenter {

    func setupInitialState() {
        
    }
}
