import SwiftUI

final class ___VARIABLE_ModuleName___Module {

    @discardableResult
    static func create(app: Application) -> UIViewController {
        let router = ___VARIABLE_ModuleName___Router(app: app)
        let interactor = ___VARIABLE_ModuleName___Interactor()
        let presenter = ___VARIABLE_ModuleName___Presenter(interactor: interactor, router: router)
        let view = ___VARIABLE_ModuleName___View().environmentObject(presenter)
        let viewController = SceneViewController(viewModel: presenter, content: view)

        router.viewController = viewController

        return viewController
    }

}
