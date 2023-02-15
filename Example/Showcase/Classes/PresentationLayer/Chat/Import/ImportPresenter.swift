import UIKit
import Combine

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
    func didPressImport() async throws {
        guard let importAccount = ImportAccount(input: input)
        else { return input = .empty }

        interactor.save(importAccount: importAccount)
        try await interactor.register(importAccount: importAccount)
        router.presentChat(importAccount: importAccount)
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
}
