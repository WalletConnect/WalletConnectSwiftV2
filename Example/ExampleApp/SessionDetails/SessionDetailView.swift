import SwiftUI
import WalletConnectSign

struct SessionDetailView: View {
    
    @ObservedObject var viewModel: SessionDetailViewModel
    
    var didPressSessionRequest: ((Request) -> Void)?
    
    var body: some View {
        List {
            Section { headerView() }
            
            ForEach(viewModel.chains, id: \.self) { chain in
                Section(header: header(chain: chain)) {
                    if let namespace = viewModel.namespace(for: chain) {
                    
                        if namespace.accounts.isNotEmpty {
                            accountSection(chain: chain, namespace: namespace)
                        }
                        
                        if namespace.methods.isNotEmpty {
                            methodsSection(chain: chain, namespace: namespace)
                        }
                        
                        if namespace.events.isNotEmpty {
                            methodsSection(chain: chain, namespace: namespace)
                        }
                    }
                }
            }
            
            if viewModel.requests.isNotEmpty {
                requestsSection()
            }
        }
        .listStyle(.insetGrouped)
    }
}

private extension SessionDetailView {
    
    func accountSection(chain: String, namespace: SessionNamespaceViewModel) -> some View {
        Section(header: headerRow("Accounts")) {
            ForEach(namespace.accounts, id: \.self) { account in
                plainRow(account.absoluteString)
            }
            .onDelete { indices in Task {
                await viewModel.remove(field: .accounts, at: indices, for: chain)
            }}
        }
    }
    
    func methodsSection(chain: String, namespace: SessionNamespaceViewModel) -> some View {
        Section(header: headerRow("Methods")) {
            ForEach(namespace.methods, id: \.self) { method in
                plainRow(method)
            }
            .onDelete { indices in Task {
                await viewModel.remove(field: .methods, at: indices, for: chain)
            }}
        }
    }
    
    func eventsSection(chain: String, namespace: SessionNamespaceViewModel) -> some View {
        Section(header: headerRow("Events")) {
            ForEach(namespace.events, id: \.self) { event in
                plainRow(event)
            }
            .onDelete { indices in Task {
                await viewModel.remove(field: .events, at: indices, for: chain)
            }}
        }
    }
    
    func requestsSection() -> some View {
        Section(header: Text("Pending requests")) {
            ForEach(viewModel.requests, id: \.method) { request in
                Button(action: { didPressSessionRequest?(request) }) {
                    plainRow(request.method)
                }
            }
        }
    }
    
    func headerView() -> some View {
        VStack(spacing: 12.0) {
            AsyncImage(url: viewModel.peerIconURL) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .clipShape(Circle())
            } placeholder: {
                ProgressView().progressViewStyle(.circular)
            }
            .frame(width: 64, height: 64)
            .frame(maxWidth: .infinity)
            
            Text(viewModel.peerName)
                .font(.headline)
            
            VStack {
                Text(viewModel.peerDescription)
                Text(viewModel.peerURL)
            }
            .font(.footnote)
            .foregroundColor(.secondaryLabel)
            
            Button("Ping") {
                viewModel.ping()
            }
            .buttonStyle(BorderedProminentButtonStyle())
        }
        .background(Color(.systemGroupedBackground))
        .listRowInsets(EdgeInsets())
        .alert("Received ping response", isPresented: $viewModel.pingSuccess) {
            Button("OK", role: .cancel) { }
        }
        .alert("Ping failed", isPresented: $viewModel.pingFailed) {
            Button("OK", role: .cancel) { }
        }
    }
    
    func headerRow(_ text: String) -> some View {
        return Text(text)
            .font(.footnote)
            .foregroundColor(.secondaryLabel)
    }
    
    func plainRow(_ text: String) -> some View {
        return Text(text)
            .font(.body)
    }
    
    func header(chain: String) -> some View {
        HStack {
            Text(chain)
            Spacer()
            Button("Delete") { Task {
                await viewModel.remove(field: .chain, for: chain)
            }}
        }
    }
}
