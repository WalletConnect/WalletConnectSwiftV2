import UIKit
import Combine
import WalletConnectSign

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

    @MainActor
    func didPressWeb3Modal() async throws {
        router.presentWeb3Modal()
    }
    
    @MainActor
    func didPressImport() async throws {
        guard let account = ImportAccount(input: input)
        else { return input = .empty }
        try await importAccount(account)
    }


    func didPressRandom() async throws {
        let account = ImportAccount.new()
        try await importAccount(account)
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
        Sign.instance.sessionSettlePublisher.sink { session in
            let accounts = session.namespaces.values.reduce(into: []) { result, namespace in
                result = result + Array(namespace.accounts)
            }

            Task(priority: .userInitiated) {
                try await self.importAccount(.web3Modal(account: accounts.first!))
            }

        }.store(in: &disposeBag)
    }

    @MainActor
    func importAccount(_ importAccount: ImportAccount) async throws {
        interactor.save(importAccount: importAccount)
        try await interactor.register(importAccount: importAccount)
        router.presentChat(importAccount: importAccount)
    }
}
