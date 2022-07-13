import UIKit
import Combine
import WalletConnectUtils

final class InvitePresenter: ObservableObject {

    private let interactor: InviteInteractor
    private let router: InviteRouter
    private let account: Account
    private var disposeBag = Set<AnyCancellable>()

    @Published var input: String = .empty {
        didSet { didInputChanged() }
    }

    lazy var rightBarButtonItem: UIBarButtonItem? = {
        let item = UIBarButtonItem(
            title: "Invite",
            style: .plain,
            target: self,
            action: #selector(invite)
        )
        item.isEnabled = false
        return item
    }()

    init(interactor: InviteInteractor, router: InviteRouter, account: Account) {
        self.interactor = interactor
        self.router = router
        self.account = account
    }

    @MainActor
    func setupInitialState() async {

    }
}

// MARK: SceneViewModel

extension InvitePresenter: SceneViewModel {

    var sceneTitle: String? {
        return "New Chat"
    }

    var largeTitleDisplayMode: UINavigationItem.LargeTitleDisplayMode {
        return .always
    }
}

// MARK: Privates

private extension InvitePresenter {

    @MainActor
    @objc func invite() {
        guard let peerAccount = AccountNameResolver.resolveAccount(input) else { return }
        Task(priority: .userInitiated) {
            await interactor.invite(peerAccount: peerAccount, message: "Welcome to WalletConnect Chat!", selfAccount: account)
            router.dismiss()
        }
    }

    func didInputChanged() {
        rightBarButtonItem?.isEnabled = !input.isEmpty
    }
}
