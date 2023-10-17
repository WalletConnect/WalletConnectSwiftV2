import SwiftUI

struct BrowserView: View {
    @EnvironmentObject var viewModel: BrowserPresenter

    @State private var selectedBrowser = 0
    
    var body: some View {
        VStack {
            Picker("", selection: $selectedBrowser) {
                Text("WKWebView").tag(0)
                Text("SafariViewController").tag(1)
            }
            .pickerStyle(.segmented)
            .padding()
            
            ZStack {
                if selectedBrowser == 0 {
                    WebView(url: URL(string: "https://react-app.walletconnect.com")!)
                } else {
                    SafariWebView(url: URL(string: "https://react-app.walletconnect.com")!)
                }
            }
        }
    }
}
