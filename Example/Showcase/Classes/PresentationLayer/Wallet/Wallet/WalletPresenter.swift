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
        guard let string = UIPasteboard.general.string, let uri = WalletConnectURI(string: string) else { return }
        print(uri)
        pair(uri: uri)
    }

    func didScanPairingURI() {
        router.presentScan { [unowned self] value in
            guard let uri = WalletConnectURI(string: value) else { return }
            self.pair(uri: uri)
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

    func pair(uri: WalletConnectURI) {
        Task(priority: .high) { [unowned self] in
            try await self.interactor.pair(uri: uri)
        }
    }
}
