import UIKit
import Combine

final class ScanPresenter: ObservableObject {
    private let interactor: ScanInteractor
    private let router: ScanRouter

    private var disposeBag = Set<AnyCancellable>()

    let onValue: (String) -> Void
    let onError: (Error) -> Void

    init(
        interactor: ScanInteractor,
        router: ScanRouter,
        onValue: @escaping (String) -> Void,
        onError: @escaping (Error) -> Void
    ) {
        defer { setupInitialState() }
        self.interactor = interactor
        self.router = router
        self.onValue = onValue
        self.onError = onError
    }
    
    func dismiss() {
        router.dismiss()
    }
}


// MARK: - Private functions
private extension ScanPresenter {
    func setupInitialState() {

    }
}

// MARK: - SceneViewModel
extension ScanPresenter: SceneViewModel {

}
