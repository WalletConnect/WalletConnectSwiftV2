import SwiftUI
import React

final class WelcomeModule {

    @discardableResult
    static func create(app: Application) -> UIViewController {
        let router = WelcomeRouter(app: app)
        let interactor = WelcomeInteractor(chatService: app.chatService, accountStorage: app.accountStorage)
        let presenter = WelcomePresenter(router: router, interactor: interactor)
        let view = WelcomeView().environmentObject(presenter)
        let viewController = UIHostingController(rootView: view)
        
        let jsCodeLocation = URL(string: "http://localhost:8081/index.bundle?platform=ios")!
        
        let rnView = RCTRootView(
            bundleURL: jsCodeLocation,
            moduleName: "Web3ModalBridge",
            initialProperties: nil,
            launchOptions: nil
        )
        
        
        viewController.view.addSubview(rnView)
        rnView.frame = CGRect(x: 50, y: 50, width: 100, height: 50)
        rnView.backgroundColor = UIColor(white:1, alpha: 0)
        router.viewController = viewController
        

        return viewController
    }

}
