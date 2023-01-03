import Foundation
import WebKit
import WalletConnectChat

final class Web3InboxClientFactory {

    static func create(chatClient: ChatClient) -> Web3InboxClient {
        let host = "https://web3inbox-dev-hidden-git-feat-add-w3i-proxy-walletconnect1.vercel.app/?noClientMode=true"
        let webviewSubscriber = WebViewRequestSubscriber()
        let webView = WebViewFactory(host: host, webviewSubscriber: webviewSubscriber).create()
        let webViewProxy = WebViewProxy(webView: webView)
        let clientProxy = ChatClientProxy(client: chatClient)
        let clientSubscriber = ChatClientRequestSubscriper(chatClient: chatClient)

        return Web3InboxClient(
            webView: webView,
            clientProxy: clientProxy,
            clientSubscriber: clientSubscriber,
            webviewProxy: webViewProxy,
            webviewSubscriber: webviewSubscriber
        )
    }
}
