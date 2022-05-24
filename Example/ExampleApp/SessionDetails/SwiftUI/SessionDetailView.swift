import SwiftUI

struct SessionDetailView: View {
    
    @ObservedObject var viewModel: SessionDetailViewModel
    
    var body: some View {
        List {
            Section { headerView() }
            
            ForEach(viewModel.chains, id: \.self) { chain in
                Section(header: header(chain: chain)) {
                    if let namespace = viewModel.namespace(for: chain) {
                        Section(header: headerRow("Accounts")) {
                            ForEach(namespace.accounts, id: \.self) { account in
                                plainRow(account.absoluteString)
                            }
                            .onDelete { indices in Task {
                                await viewModel.remove(field: .accounts, at: indices, for: chain)
                            }}
                        }
                        
                        Section(header: headerRow("Methods")) {
                            ForEach(namespace.methods, id: \.self) { method in
                                plainRow(method)
                            }
                            .onDelete { indices in Task {
                                await viewModel.remove(field: .methods, at: indices, for: chain)
                            }}
                        }
                        
                        Section(header: headerRow("Events")) {
                            ForEach(namespace.events, id: \.self) { event in
                                plainRow(event)
                            }
                            .onDelete { indices in Task {
                                await viewModel.remove(field: .events, at: indices, for: chain)
                            }}
                        }
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
    }
}

private extension SessionDetailView {
    
    func headerView() -> some View {
        VStack(spacing: 8.0) {
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
        }
        .background(Color(.systemGroupedBackground))
        .listRowInsets(EdgeInsets())
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
            Button("Delete Chain") { Task {
                await viewModel.remove(field: .chain, for: chain)
            }}
        }
    }
}
