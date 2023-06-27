import UIKit
import Combine
import WalletConnectModal

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
    func didPressWalletConnectModal() async throws {
        router.presentWalletConnectModal()

        let session: Session = try await withCheckedThrowingContinuation { continuation in
            var cancellable: AnyCancellable?
            cancellable = WalletConnectModal.instance.sessionSettlePublisher.sink { session in
                defer { cancellable?.cancel() }
                return continuation.resume(returning: session)
            }
        }

        guard let account = session.accounts.first(where: { $0.blockchain.absoluteString == "eip155:1" }) else {
            throw AlertError(message: "No matching accounts found in namespaces")
        }

        try await importAccount(.web3Modal(account: account, topic: session.topic))
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

    }

    @MainActor
    func importAccount(_ importAccount: ImportAccount) async throws {
        try await interactor.register(importAccount: importAccount)
        interactor.save(importAccount: importAccount)
        router.presentChat(importAccount: importAccount)
    }
}
