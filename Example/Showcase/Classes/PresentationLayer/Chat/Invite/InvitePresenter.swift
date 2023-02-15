import UIKit
import Combine

final class InvitePresenter: ObservableObject {

    private let interactor: InviteInteractor
    private let router: InviteRouter
    private let account: Account
    private var disposeBag = Set<AnyCancellable>()

    @Published var input: String = .empty {
        didSet { didInputChanged() }
    }

    var showButton: Bool {
        return ImportAccount(input: input) != nil
    }

    init(interactor: InviteInteractor, router: InviteRouter, account: Account) {
        self.interactor = interactor
        self.router = router
        self.account = account
    }

    @MainActor
    func invite() async throws {
        guard let inviteeAccount = ImportAccount(input: input)?.account else { return }
        try await interactor.invite(inviterAccount: self.account, inviteeAccount: inviteeAccount, message: "Welcome to WalletConnect Chat!")
        router.dismiss()
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

    func didInputChanged() {
        rightBarButtonItem?.isEnabled = !input.isEmpty
    }
}
