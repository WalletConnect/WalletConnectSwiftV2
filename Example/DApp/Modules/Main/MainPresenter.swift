import UIKit
import WalletConnectSign
import Combine

final class MainPresenter {
    private let interactor: MainInteractor
    private let router: MainRouter
    private var disposeBag = Set<AnyCancellable>()

    var tabs: [TabPage] {
        return TabPage.allCases
    }

    var viewControllers: [UIViewController] {
        return [
            router.signViewController(),
            router.authViewController()
        ]
    }

    init(router: MainRouter, interactor: MainInteractor) {
        defer {
            setupInitialState()
        }
        self.router = router
        self.interactor = interactor
    }

    private func setupInitialState() {
        Sign.instance.sessionResponsePublisher
            .receive(on: DispatchQueue.main)
            .sink { [unowned self] response in
                Task(priority: .high) { await ActivityIndicatorManager.shared.stop() }
                presentResponse(response: response)
            }
            .store(in: &disposeBag)
    }

    private func presentResponse(response: Response) {

    }
}
