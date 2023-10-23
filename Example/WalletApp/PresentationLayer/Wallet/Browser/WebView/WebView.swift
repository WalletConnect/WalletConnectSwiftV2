import SwiftUI
import WebKit

struct WebView: UIViewRepresentable {
    let url: URL
    
    @ObservedObject var viewModel: BrowserPresenter
    
    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        viewModel.webView = webView
        webView.load(URLRequest(url: url))
        return webView
    }
    
    func updateUIView(_ uiView: WKWebView, context: Context) {
        
    }
}
