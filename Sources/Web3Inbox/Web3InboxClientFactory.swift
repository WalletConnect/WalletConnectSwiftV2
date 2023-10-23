import Foundation
import WebKit

final class Web3InboxClientFactory {

    static func create(
        chatClient: ChatClient,
        notifyClient: NotifyClient,
        account: Account,
        config: [ConfigParam: Bool],
        onSign: @escaping SigningCallback
    ) -> Web3InboxClient {
        let url = buildUrl(account: account, config: config)

        let logger = ConsoleLogger(prefix: "📬", loggingLevel: .off)
        let webviewSubscriber = WebViewRequestSubscriber(url: url, logger: logger)
        let webView = WebViewFactory(url: url, webviewSubscriber: webviewSubscriber).create()
        let chatWebViewProxy = WebViewProxy(webView: webView, scriptFormatter: ChatWebViewScriptFormatter(), logger: logger)
        let notifyWebViewProxy = WebViewProxy(webView: webView, scriptFormatter: NotifyWebViewScriptFormatter(), logger: logger)

        let clientProxy = ChatClientProxy(client: chatClient, onSign: onSign)
        let clientSubscriber = ChatClientRequestSubscriber(chatClient: chatClient, logger: logger)

        let notifyClientProxy = NotifyClientProxy(client: notifyClient, onSign: onSign)
        let notifyClientSubscriber = NotifyClientRequestSubscriber(client: notifyClient, logger: logger)

        return Web3InboxClient(
            webView: webView,
            account: account,
            logger: logger,
            chatClientProxy: clientProxy,
            clientSubscriber: clientSubscriber,
            chatWebviewProxy: chatWebViewProxy,
            notifyWebviewProxy: notifyWebViewProxy,
            webviewSubscriber: webviewSubscriber,
            notifyClientProxy: notifyClientProxy,
            notifyClientSubscriber: notifyClientSubscriber,
            notifyClient: notifyClient
        )
    }

    private static func buildUrl(account: Account, config: [ConfigParam: Bool]) -> URL {
        var urlComponents = URLComponents(string: "https://web3inbox-dev-hidden-git-chore-notif-refa-effa6b-walletconnect1.vercel.app/")!
        var queryItems = [URLQueryItem(name: "chatProvider", value: "ios"), URLQueryItem(name: "notifyProvider", value: "ios"), URLQueryItem(name: "account", value: account.address), URLQueryItem(name: "authProvider", value: "ios")]

        for param in config.filter({ $0.value == false}) {
            queryItems.append(URLQueryItem(name: "\(param.key)", value: "false"))
        }
        urlComponents.queryItems = queryItems
        return urlComponents.url!
    }
}
