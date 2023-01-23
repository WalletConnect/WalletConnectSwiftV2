import UIKit
import Combine
import Auth

final class WelcomePresenter: ObservableObject {

    private let router: WelcomeRouter
    private let interactor: WelcomeInteractor

    @Published var connected: Bool = false

    init(router: WelcomeRouter, interactor: WelcomeInteractor) {
        self.router = router
        self.interactor = interactor
    }

    @MainActor
    func setupInitialState() async {
        for await connected in interactor.trackConnection() {
            print("Client connection status: \(connected)")
            self.connected = connected == .connected
        }
    }

    var buttonTitle: String {
        return interactor.isAuthorized() ? "Start Messaging" : "Connect wallet"
    }

    func didPressImport() {
        if let account = interactor.account {
            router.presentChats(account: account)
        } else {
            router.presentImport()
        }
    }
    
    private func authWithWallet() async {
        let uri = await interactor.generateUri()
        try? await Auth.instance.request(
            RequestParams(
                domain: "example.wallet",
                chainId: "eip155:1",
                nonce: "32891756",
                aud: "https://example.wallet/login",
                nbf: nil,
                exp: nil,
                statement: "I accept the ServiceOrg Terms of Service: https://service.invalid/tos",
                requestId: nil,
                resources: ["ipfs://bafybeiemxf5abjwjbikoz4mc3a3dla6ual3jsgpdr4cjr3oz3evfyavhwq/", "https://example.com/my-web2-claim.json"]
            ),
            topic: uri.topic
        )
        
        DispatchQueue.main.async {
            self.router.openWallet(uri: uri.absoluteString)
        }
    }
}
