import UIKit
import Combine

final class PasteUriPresenter: ObservableObject {
    private let interactor: PasteUriInteractor
    private let router: PasteUriRouter
    private var disposeBag = Set<AnyCancellable>()

    let onValue: (String) -> Void
    let onError: (Error) -> Void
    
    init(
        interactor: PasteUriInteractor,
        router: PasteUriRouter,
        onValue: @escaping (String) -> Void,
        onError: @escaping (Error) -> Void
    ) {
        defer {
            setupInitialState()
        }
        self.interactor = interactor
        self.router = router
        self.onValue = onValue
        self.onError = onError
    }
}

// MARK: - Private functions
extension PasteUriPresenter {
    private func setupInitialState() {

    }
}

// MARK: - SceneViewModel
extension PasteUriPresenter: SceneViewModel {

}
