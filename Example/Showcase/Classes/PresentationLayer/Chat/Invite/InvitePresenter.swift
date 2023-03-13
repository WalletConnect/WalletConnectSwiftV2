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
        return validation(from: input)
    }

    init(interactor: InviteInteractor, router: InviteRouter, account: Account) {
        self.interactor = interactor
        self.router = router
        self.account = account
    }

    @MainActor
    func invite() async throws {
        let inviteeAccount = try await resolveAccount(from: input)

        try await interactor.invite(inviterAccount: account, inviteeAccount: inviteeAccount, message: "Welcome to WalletConnect Chat!")

        await dismiss()
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
    func dismiss() async {
        router.dismiss()
    }

    func didInputChanged() {
        rightBarButtonItem?.isEnabled = !input.isEmpty
    }

    func validation(from input: String) -> Bool {
        if let _ = Account(input) {
            return true
        }
        if let _ = ImportAccount(input: input)?.account {
            return true
        }
        if let _ = try? EthereumAddress(hex: input, eip55: false) {
            return true
        }

        let components = input.components(separatedBy: ".")
        if components.count > 1, !components.contains("") {
            return true
        }
        return false
    }

    func resolveAccount(from input: String) async throws -> Account {
        if let account = Account(input) {
            return account
        }
        if let account = ImportAccount(input: input)?.account {
            return account
        }
        if let address = try? EthereumAddress(hex: input, eip55: false) {
            return Account("eip155:1:\(address.hex(eip55: true))")!
        }
        return try await interactor.resolve(ens: input)
    }
}
