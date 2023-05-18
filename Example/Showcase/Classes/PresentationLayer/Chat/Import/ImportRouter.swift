import UIKit
import Web3Modal
import WalletConnectPairing

final class ImportRouter {

    weak var viewController: UIViewController!

    private let app: Application

    init(app: Application) {
        self.app = app
    }
    
    func presentWeb3Modal() {
        Web3ModalSheetController(
            projectId: InputConfig.projectId,
            metadata: AppMetadata(
                name: "Showcase App",
                description: "Showcase description",
                url: "example.wallet",
                icons: ["https://avatars.githubusercontent.com/u/37784886"]
            ),
            webSocketFactory: DefaultSocketFactory()
        ).present(from: viewController)
    }

    func presentChat(importAccount: ImportAccount) {
        MainModule.create(app: app, importAccount: importAccount).present()
    }
}
