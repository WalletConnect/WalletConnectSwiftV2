import SwiftUI

final class ScanModule {
    @discardableResult
    static func create(
        app: Application,
        onValue: @escaping (String) -> Void,
        onError: @escaping (Error) -> Void
    ) -> UIViewController {
        let router = ScanRouter(app: app)
        let interactor = ScanInteractor()
        let presenter = ScanPresenter(interactor: interactor, router: router, onValue: onValue, onError: onError)
        let view = ScanView().environmentObject(presenter)
        let viewController = SceneViewController(viewModel: presenter, content: view)

        router.viewController = viewController

        return viewController
    }
}
