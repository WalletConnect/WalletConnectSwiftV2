import UIKit
import Combine

final class ___VARIABLE_ModuleName___Presenter: ObservableObject {

    private let interactor: ___VARIABLE_ModuleName___Interactor
    private let router: ___VARIABLE_ModuleName___Router
    private var disposeBag = Set<AnyCancellable>()

    init(interactor: ___VARIABLE_ModuleName___Interactor, router: ___VARIABLE_ModuleName___Router) {
        defer { setupInitialState() }
        self.interactor = interactor
        self.router = router
    }
}

// MARK: SceneViewModel

extension ___VARIABLE_ModuleName___Presenter: SceneViewModel {

}

// MARK: Privates

private extension ___VARIABLE_ModuleName___Presenter {

    func setupInitialState() {

    }
}
