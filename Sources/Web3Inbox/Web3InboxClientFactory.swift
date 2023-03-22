import Foundation
import WebKit

final class Web3InboxClientFactory {

    static func create(
        chatClient: ChatClient,
        account: Account,
        onSign: @escaping SigningCallback
    ) -> Web3InboxClient {
        let host = hostUrlString(account: account)
        let logger = ConsoleLogger(suffix: "📬")
        let webviewSubscriber = WebViewRequestSubscriber(logger: logger)
        let webView = WebViewFactory(host: host, webviewSubscriber: webviewSubscriber).create()
        let webViewProxy = WebViewProxy(webView: webView)
        let clientProxy = ChatClientProxy(client: chatClient, onSign: onSign)
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

    private static func hostUrlString(account: Account) -> String {
        return "https://web3inbox-dev-hidden.vercel.app/?chatProvider=ios&account=\(account.address)"
    }
}
