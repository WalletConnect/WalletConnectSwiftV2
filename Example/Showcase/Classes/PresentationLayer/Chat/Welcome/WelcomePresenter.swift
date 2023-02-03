import UIKit
import Combine
import Auth

final class WelcomePresenter: ObservableObject {

    private let router: WelcomeRouter
    private let interactor: WelcomeInteractor

    @Published var connected: Bool = false

    init(router: WelcomeRouter, interactor: WelcomeInteractor) {
        self.router = router
        self.interactor = interactor
    }

    @MainActor
    func setupInitialState() async {
        for await connected in interactor.trackConnection() {
            print("Client connection status: \(connected)")
            self.connected = connected == .connected
        }
    }

    var buttonTitle: String {
        return interactor.isAuthorized() ? "Start Messaging" : "Connect wallet"
    }

    func didPressImport() {
        if let account = interactor.account {
            router.presentMain(account: account)
        } else {
            router.presentImport()
        }
    }
}
