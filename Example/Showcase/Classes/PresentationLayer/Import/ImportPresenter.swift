import UIKit
import Combine
import WalletConnectUtils

final class ImportPresenter: ObservableObject {

    private let interactor: ImportInteractor
    private let router: ImportRouter
    private var disposeBag = Set<AnyCancellable>()

    @Published var input: String = .empty

    init(interactor: ImportInteractor, router: ImportRouter) {
        defer { setupInitialState() }
        self.interactor = interactor
        self.router = router
    }

    func didPressImport() {
        guard let account = AccountNameResolver.resolveAccount(input)
        else { return input = .empty }
        interactor.save(account: account)
        register(account: account)
        router.presentChat(account: account)
    }
}

// MARK: SceneViewModel

extension ImportPresenter: SceneViewModel {

    var sceneTitle: String? {
        return "Import account"
    }

    var largeTitleDisplayMode: UINavigationItem.LargeTitleDisplayMode {
        return .always
    }
}

// MARK: Privates

private extension ImportPresenter {

    func setupInitialState() {

    }

    func register(account: Account) {
        Task(priority: .high) {
            await interactor.register(account: account)
        }
    }
}
