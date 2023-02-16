import UIKit
import Combine
import Web3

final class InvitePresenter: ObservableObject {

    private let interactor: InviteInteractor
    private let router: InviteRouter
    private let account: Account
    private var disposeBag = Set<AnyCancellable>()

    @Published var input: String = .empty {
        didSet { didInputChanged() }
    }

    var showButton: Bool {
        return resolveAccount(from: input) != nil
    }

    init(interactor: InviteInteractor, router: InviteRouter, account: Account) {
        self.interactor = interactor
        self.router = router
        self.account = account
    }

    @MainActor
    func invite() async throws {
        guard let inviteeAccount = resolveAccount(from: input)
        else { return }

        try await interactor.invite(inviterAccount: account, inviteeAccount: inviteeAccount, message: "Welcome to WalletConnect Chat!")
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

    func resolveAccount(from input: String) -> Account? {
        if let account = Account(input) {
            return account
        }
        if let account = ImportAccount(input: input)?.account {
            return account
        }
        if let address = try? EthereumAddress(hex: input, eip55: false) {
            return Account("eip155:1:\(address.hex(eip55: true))")!
        }
        return nil
    }
}
