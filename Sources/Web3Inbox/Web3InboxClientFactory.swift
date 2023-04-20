import Foundation
import WebKit

final class Web3InboxClientFactory {

    static func create(
        chatClient: ChatClient,
        pushClient: WalletPushClient,
        account: Account,
        onSign: @escaping SigningCallback
    ) -> Web3InboxClient {
        let host = hostUrlString(account: account)
        let logger = ConsoleLogger(suffix: "📬")
        let chatWebviewSubscriber = WebViewRequestSubscriber(logger: logger)
        let pushWebviewSubscriber = WebViewRequestSubscriber(logger: logger)
        let webView = WebViewFactory(host: host, chatWebviewSubscriber: chatWebviewSubscriber, pushWebviewSubscriber: pushWebviewSubscriber).create()
        let chatWebViewProxy = WebViewProxy(webView: webView, scriptFormatter: ChatWebViewScriptFormatter())
        let pushWebViewProxy = WebViewProxy(webView: webView, scriptFormatter: PushWebViewScriptFormatter())

        let clientProxy = ChatClientProxy(client: chatClient, onSign: onSign)
        let clientSubscriber = ChatClientRequestSubscriber(chatClient: chatClient, logger: logger)

        let pushClientProxy = PushClientProxy(client: pushClient, onSign: onSign)
        let pushClientSubscriber = PushClientRequestSubscriber(client: pushClient, logger: logger)

        return Web3InboxClient(
            webView: webView,
            account: account,
            logger: ConsoleLogger(),
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

    private static func hostUrlString(account: Account) -> String {
        return "https://web3inbox-dev-hidden-git-feat-targeted-ex-3bf147-walletconnect1.vercel.app/?chatProvider=ios&pushProvider=ios&account=\(account.address)"
    }
}
