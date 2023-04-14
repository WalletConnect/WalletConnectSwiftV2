import SwiftUI

final class PasteUriModule {
    @discardableResult
    static func create(
        app: Application,
        onValue: @escaping (String) -> Void,
        onError: @escaping (Error) -> Void
    ) -> UIViewController {
        let router = PasteUriRouter(app: app)
        let interactor = PasteUriInteractor()
        let presenter = PasteUriPresenter(
            interactor: interactor,
            router: router,
            onValue: onValue,
            onError: onError
        )
        let view = PasteUriView().environmentObject(presenter)
        let viewController = SceneViewController(viewModel: presenter, content: view)

        router.viewController = viewController

        return viewController
    }
}
