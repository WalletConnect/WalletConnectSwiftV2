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
                    VStack {
                        HStack {
                            TextField(
                                viewModel.urlString,
                                text: $viewModel.urlString
                            )
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .onSubmit {
                                viewModel.loadURLString()
                            }
                            
                            Button {
                                viewModel.reload()
                            } label: {
                                Image(systemName: "arrow.clockwise")
                            }
                        }
                        .padding(.horizontal)
                        
                        Divider()
                            .padding(.top)
                        
                        if let url = URL(string: viewModel.urlString) {
                            WebView(url: url, viewModel: viewModel)
                        }
                        
                        Spacer()
                    }
                    .onAppear {
                        viewModel.loadURLString()
                    }
                } else {
                    if let url = URL(string: viewModel.urlString) {
                        SafariWebView(url: url.sanitise)
                    }
                }
            }
        }
    }
}

#if DEBUG
struct BrowserView_Previews: PreviewProvider {
    static var previews: some View {
        BrowserView()
    }
}
#endif
