import UIKit
import Combine
import Auth

final class WalletPresenter: ObservableObject {

    private let interactor: WalletInteractor
    private let router: WalletRouter
    private var disposeBag = Set<AnyCancellable>()

    init(interactor: WalletInteractor, router: WalletRouter) {
        defer { setupInitialState() }
        self.interactor = interactor
        self.router = router
    }

    func didPastePairingURI() {
        guard let uri = UIPasteboard.general.string else { return }
        pair(uri: uri)
    }

    func didScanPairingURI() {
        router.presentScan { [unowned self] value in
            self.pair(uri: value)
            self.router.dismiss()
        } onError: { error in
            print(error.localizedDescription)
            self.router.dismiss()
        }
    }
}

// MARK: SceneViewModel

extension WalletPresenter: SceneViewModel {

    var sceneTitle: String? {
        return "Wallet"
    }

    var largeTitleDisplayMode: UINavigationItem.LargeTitleDisplayMode {
        return .always
    }
}

// MARK: Privates

private extension WalletPresenter {

    func setupInitialState() {
        interactor.requestPublisher.sink { [unowned self] request in
            self.router.present(request: request)
        }.store(in: &disposeBag)
    }

    func pair(uri: String) {
        Task(priority: .high) { [unowned self] in
            try await self.interactor.pair(uri: uri)
        }
    }
}
