import Foundation
import WebKit

final class Web3InboxClientFactory {

    static func create(
        chatClient: ChatClient,
        pushClient: WalletPushClient,
        account: Account,
        config: [ConfigParam: Bool],
        onSign: @escaping SigningCallback
    ) -> Web3InboxClient {
        let url = buildUrl(account: account, config: config)
        let logger = ConsoleLogger(suffix: "📬", loggingLevel: .debug)
        let chatWebviewSubscriber = WebViewRequestSubscriber(logger: logger)
        let pushWebviewSubscriber = WebViewRequestSubscriber(logger: logger)
        let webView = WebViewFactory(url: url, chatWebviewSubscriber: chatWebviewSubscriber, pushWebviewSubscriber: pushWebviewSubscriber).create()
        let chatWebViewProxy = WebViewProxy(webView: webView, scriptFormatter: ChatWebViewScriptFormatter(), logger: logger)
        let pushWebViewProxy = WebViewProxy(webView: webView, scriptFormatter: PushWebViewScriptFormatter(), logger: logger)

        let clientProxy = ChatClientProxy(client: chatClient, onSign: onSign)
        let clientSubscriber = ChatClientRequestSubscriber(chatClient: chatClient, logger: logger)

        let pushClientProxy = PushClientProxy(client: pushClient, onSign: onSign)
        let pushClientSubscriber = PushClientRequestSubscriber(client: pushClient, logger: logger)

        return Web3InboxClient(
            webView: webView,
            account: account,
            logger: logger,
            chatClientProxy: clientProxy,
            clientSubscriber: clientSubscriber,
            chatWebviewProxy: chatWebViewProxy,
            pushWebviewProxy: pushWebViewProxy,
            chatWebviewSubscriber: chatWebviewSubscriber,
            pushWebviewSubscriber: pushWebviewSubscriber,
            pushClientProxy: pushClientProxy,
            pushClientSubscriber: pushClientSubscriber
        )
    }

    private static func buildUrl(account: Account, config: [ConfigParam: Bool]) -> URL {
        var urlComponents = URLComponents(string: "https://web3inbox-dev-hidden.vercel.app/")!
        var queryItems = [URLQueryItem(name: "chatProvider", value: "ios"), URLQueryItem(name: "pushProvider", value: "ios"), URLQueryItem(name: "account", value: account.address)]

        for param in config.filter({ $0.value == false}) {
            queryItems.append(URLQueryItem(name: "\(param.key)", value: "false"))
        }
        urlComponents.queryItems = queryItems
        return urlComponents.url!
    }
}
