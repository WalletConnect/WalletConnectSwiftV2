import Foundation
import WebKit

final class Web3InboxClientFactory {

    static func create(chatClient: ChatClient, account: Account) -> Web3InboxClient {
        let host = "https://web3inbox-dev-hidden.vercel.app/?chatProvider=ios"
        let logger = ConsoleLogger(suffix: "📬")
        let webviewSubscriber = WebViewRequestSubscriber(logger: logger)
        let webView = WebViewFactory(host: host, webviewSubscriber: webviewSubscriber).create()
        let webViewProxy = WebViewProxy(webView: webView)
        let clientProxy = ChatClientProxy(client: chatClient)
        let clientSubscriber = ChatClientRequestSubscriber(chatClient: chatClient, logger: logger)

        return Web3InboxClient(
            webView: webView,
            account: account,
            logger: ConsoleLogger(),
            clientProxy: clientProxy,
            clientSubscriber: clientSubscriber,
            webviewProxy: webViewProxy,
            webviewSubscriber: webviewSubscriber
        )
    }
}
