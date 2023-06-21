import WebKit
import Foundation

class WebViewRefreshHandler {
    private var webViewURLObserver: NSKeyValueObservation!
    private let webView: WKWebView
    private let initUrl: URL
    private var isReloadingContent = false
    private let logger: ConsoleLogging

    init(webView: WKWebView,
         initUrl: URL,
         logger: ConsoleLogging) {
        self.webView = webView
        self.initUrl = initUrl
        self.logger = logger
        setUpWebViewObserver()
    }

    func setUpWebViewObserver() {
        self.webViewURLObserver = webView.observe(\.url, options: .new) { [unowned self] webview, change in
            logger.debug("URL: \(String(describing: change.newValue))")
            if let newValue = change.newValue,
               let url = newValue?.absoluteString,
               url.contains("/login"),
               !isReloadingContent {
                isReloadingContent = true
                let request = URLRequest(url: initUrl)

                webview.load(request)
                _ = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: false) { [unowned self] timer in
                    isReloadingContent = false
                }
            }
        }
    }
}
