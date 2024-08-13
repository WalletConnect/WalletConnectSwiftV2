import UIKit

import Web3Modal
import WalletConnectModal
import WalletConnectRelay
import WalletConnectNetworking
import Combine


class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?
    private var publishers = Set<AnyCancellable>()

    private let app = Application()


    func scene(_ scene: UIScene, continue userActivity: NSUserActivity) {
        ProfilingService.instance.send(logMessage: .init(message: "SceneDelegate: will try to dispatch envelope - userActivity: \(String(describing: userActivity.webpageURL))"))
        guard let url = userActivity.webpageURL,
              let components = URLComponents(url: url, resolvingAgainstBaseURL: true) else {
            return
        }
        do {
            try Sign.instance.dispatchEnvelope(url.absoluteString)
        } catch {
            print(error)
        }
    }

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        configureClientsIfNeeded()
        setUpProfilingIfNeeded()
        ProfilingService.instance.send(logMessage: .init(message: "SceneDelegate: willConnectTo : \(String(describing: connectionOptions.userActivities.first?.webpageURL?.absoluteString))"))

        configureClientsIfNeeded()
        setUpProfilingIfNeeded()


        setupWindow(scene: scene)
    }

    private func setupWindow(scene: UIScene) {
        guard let windowScene = (scene as? UIWindowScene) else { return }
        window = UIWindow(windowScene: windowScene)

        let viewController = SignModule.create(app: app)
            .wrapToNavigationController()

        window?.rootViewController = viewController
        window?.makeKeyAndVisible()
    }

    func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
        ProfilingService.instance.send(logMessage: .init(message: "SceneDelegate:  - openURLContexts : \(String(describing: URLContexts.first?.url))"))

        guard let context = URLContexts.first else { return }

        let url = context.url

        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let queryItems = components.queryItems,
              queryItems.contains(where: { $0.name == "wc_ev" }) else {
            return
        }

        do {
            try Sign.instance.dispatchEnvelope(url.absoluteString)
        } catch {
            AlertPresenter.present(message: error.localizedDescription, type: .error)
        }
    }

    func sceneWillEnterForeground(_ scene: UIScene) {
        ProfilingService.instance.send(logMessage: .init(message: "SceneDelegate: scene will enter foreground"))
        // Additional code to handle entering the foreground
    }

    func sceneDidBecomeActive(_ scene: UIScene) {
        ProfilingService.instance.send(logMessage: .init(message: "SceneDelegate: scene did become active"))
        // Additional code to handle becoming active
    }

    private func setUpProfilingIfNeeded() {
        if let clientId = try? Networking.interactor.getClientId() {
            ProfilingService.instance.setUpProfiling(account: "swift_dapp_\(clientId)", clientId: clientId)
        }
    }

    var clientsConfigured = false
    private func configureClientsIfNeeded() {
        if clientsConfigured {return}
        else {clientsConfigured = true}
        Networking.configure(
            groupIdentifier: Constants.groupIdentifier,
            projectId: InputConfig.projectId,
            socketFactory: DefaultSocketFactory()
        )

        let metadata = AppMetadata(
            name: "Swift Dapp",
            description: "WalletConnect DApp sample",
            url: "https://lab.web3modal.com/dapp",
            icons: ["https://avatars.githubusercontent.com/u/37784886"],
            redirect: try! AppMetadata.Redirect(native: "wcdapp://", universal: "https://lab.web3modal.com/dapp", linkMode: true)
        )

        Web3Modal.configure(
            projectId: InputConfig.projectId,
            metadata: metadata,
            crypto: DefaultCryptoProvider(),
            authRequestParams: .stub(), customWallets: [
                .init(
                    id: "swift-sample",
                    name: "Swift Sample Wallet",
                    homepage: "https://walletconnect.com/",
                    imageUrl: "https://avatars.githubusercontent.com/u/37784886?s=200&v=4",
                    order: 1,
                    mobileLink: "walletapp://",
                    linkMode: "https://lab.web3modal.com/wallet"
                ),
                .init(
                    id: "rn-sample",
                    name: "RN Sample Wallet",
                    homepage: "https://walletconnect.com/",
                    imageUrl: "https://avatars.githubusercontent.com/u/37784886?s=200&v=4",
                    order: 1,
                    mobileLink: "rn-web3wallet://",
                    linkMode: "https://lab.web3modal.com/walletkit_rn"
                ),
                .init(
                    id: "flutter-sample",
                    name: "Flutter Sample Wallet",
                    homepage: "https://walletconnect.com/",
                    imageUrl: "https://avatars.githubusercontent.com/u/37784886?s=200&v=4",
                    order: 1,
                    mobileLink: "wcflutterwallet://",
                    linkMode: "https://lab.web3modal.com/walletkit_flutter"
                ),
                .init(
                    id: "flutter-sample-internal",
                    name: "Flutter Sample Wallet Internal",
                    homepage: "https://walletconnect.com/",
                    imageUrl: "https://avatars.githubusercontent.com/u/37784886?s=200&v=4",
                    order: 1,
                    mobileLink: "wcflutterwallet-internal://",
                    linkMode: "https://lab.web3modal.com/walletkit_flutter_internal"
                ),
            ]
        )

        Web3Modal.instance.authResponsePublisher.sink { (id, result) in
            switch result {
            case .success((_, _)):
                AlertPresenter.present(message: "User Authenticted with SIWE", type: .success)
            case .failure(_):
                break
            }
        }.store(in: &publishers)

        WalletConnectModal.configure(
            projectId: InputConfig.projectId,
            metadata: metadata
        )

        Sign.instance.logger.setLogging(level: .debug)
        Networking.instance.setLogging(level: .debug)

        Sign.instance.logsPublisher.sink { log in
            switch log {
            case .error(let logMessage):
                AlertPresenter.present(message: logMessage.message, type: .error)
            default: return
            }
        }.store(in: &publishers)

        Sign.instance.socketConnectionStatusPublisher.sink { status in
            switch status {
            case .connected:
                AlertPresenter.present(message: "Your web socket has connected", type: .success)
            case .disconnected:
                AlertPresenter.present(message: "Your web socket is disconnected", type: .warning)
            }
        }.store(in: &publishers)

        Web3Modal.instance.disableAnalytics()
    }
}
