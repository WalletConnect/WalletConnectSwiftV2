import UIKit
import Combine
import WebKit

import WalletConnectNetworking

final class BrowserPresenter: ObservableObject {
    private let interactor: BrowserInteractor
    private let router: BrowserRouter
    
    weak var webView: WKWebView?
    
    @Published var urlString = "https://react-app.walletconnect.com"
    
    private var disposeBag = Set<AnyCancellable>()

    init(interactor: BrowserInteractor, router: BrowserRouter) {
        defer { setupInitialState() }
        self.interactor = interactor
        self.router = router
    }
    
    func loadURLString() {
        if let url = URL(string: urlString) {
            webView?.load(URLRequest(url: url.sanitise))
        }
    }
    
    func reload() {
        webView?.reload()
    }
}

// MARK: SceneViewModel
extension BrowserPresenter: SceneViewModel {
    var sceneTitle: String? {
        return "Browser"
    }

    var largeTitleDisplayMode: UINavigationItem.LargeTitleDisplayMode {
        return .never
    }
}

// MARK: Privates
private extension BrowserPresenter {
    func setupInitialState() {

    }
}

extension URL {
    var sanitise: URL {
        if var components = URLComponents(url: self, resolvingAgainstBaseURL: false) {
            if components.scheme == nil {
                components.scheme = "https"
            }
            return components.url ?? self
        }
        return self
    }
}
