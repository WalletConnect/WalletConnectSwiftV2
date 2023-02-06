import UIKit
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
            router.walletViewController(),
            router.notificationsViewController(),
        ]
    }

    init(router: MainRouter,
         interactor: MainInteractor) {
        defer {
            setupInitialState()
        }
        self.router = router
        self.interactor = interactor
    }
}

// MARK: - Private functions
extension MainPresenter {
    private func setupInitialState() {
        interactor.pushRequestPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] request in
                self?.router.present(pushRequest: request)
            }.store(in: &disposeBag)

        interactor.sessionProposalPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] proposal in
                self?.router.present(proposal: proposal)
            }
            .store(in: &disposeBag)
    }
}

