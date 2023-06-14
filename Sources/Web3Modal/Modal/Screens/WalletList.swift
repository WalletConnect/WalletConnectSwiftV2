import SwiftUI

@available(iOS 14.0, *)
struct WalletList: View {
    @Namespace var namespace
    
    @Binding var wallets: [Listing]
    @Binding var destination: Destination
    @State var retryButtonShown: Bool = false
    
    var navigateTo: (Destination) -> Void
    var onListingTap: (Listing) -> Void
    
    var body: some View {
        content()
    }
    
    @ViewBuilder
    private func content() -> some View {
        switch destination {
        case .welcome:
            initialList()
        case .viewAll:
            viewAll()
        case let .walletDetail(wallet):
            walletDetail(wallet)
        default:
            EmptyView()
        }
    }
    
    private func initialList() -> some View {
        ZStack {
            VStack {
                HStack {
                    ForEach(0..<4) { wallet in
                        gridItem(for: wallet)
                    }
                }
                HStack {
                    ForEach(4..<7) { wallet in
                        gridItem(for: wallet)
                    }
                    
                    viewAllItem()
                        .onTapGesture {
                            navigateTo(.viewAll)
                        }
                }
            }
            
            Spacer().frame(height: 200)
        }
    }
    
    private func viewAll() -> some View {
        ScrollView(.vertical) {
            VStack(alignment: .leading) {
                ForEach(Array(stride(from: 0, to: wallets.count, by: 4)), id: \.self) { row in
                    HStack {
                        ForEach(row..<(row + 4), id: \.self) { index in
                            if wallets.indices.contains(index) {
                                gridItem(for: index)
                            }
                        }
                    }
                }
            }
        }
    }
    
    @ViewBuilder
    func viewAllItem() -> some View {
        VStack {
            VStack(spacing: 3) {
                HStack(spacing: 3) {
                    ForEach(7..<9) { index in
                        WalletImage(wallet: wallets[safe: index])
                            .cornerRadius(8)
                            .aspectRatio(1, contentMode: .fit)
                    }
                }
                .padding(.horizontal, 5)
                
                HStack(spacing: 3) {
                    ForEach(9..<11) { index in
                        WalletImage(wallet: wallets[safe: index])
                            .cornerRadius(8)
                            .aspectRatio(1, contentMode: .fit)
                    }
                }
                .padding(.horizontal, 5)
            }
            .padding(.vertical, 3)
            .frame(width: 60, height: 60)
            .background(Color.background2)
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(.gray.opacity(0.4), lineWidth: 1)
            )
            
            Text("View All")
                .font(.system(size: 12))
                .foregroundColor(.foreground1)
                .padding(.horizontal, 12)
                .fixedSize(horizontal: true, vertical: true)
            
            Spacer()
        }
        .frame(maxWidth: 80, maxHeight: 96)
    }
    
    @ViewBuilder
    func gridItem(for index: Int) -> some View {
        let wallet: Listing? = wallets[safe: index]
        
        VStack {
            WalletImage(wallet: wallet)
                .frame(width: 60, height: 60)
                .matchedGeometryEffect(id: index, in: namespace)
            
            Text(wallet?.name ?? "WalletName")
                .font(.system(size: 12))
                .foregroundColor(.foreground1)
                .padding(.horizontal, 12)
                .multilineTextAlignment(.center)
                .minimumScaleFactor(0.4)
            
            Text("RECENT")
                .opacity(0)
                .font(.system(size: 10))
                .foregroundColor(.foreground3)
                .padding(.horizontal, 12)
        }
        .redacted(reason: wallet == nil ? .placeholder : [])
        .frame(maxWidth: 80, maxHeight: 96)
        .onTapGesture {
            guard let wallet else { return }
            
            navigateTo(.walletDetail(wallet))
        }
    }
    
    private func walletDetail(_ wallet: Listing) -> some View {
        VStack(spacing: 8) {
            WalletImage(wallet: wallet, size: .large)
                .frame(maxWidth: 96, maxHeight: 96)
            
            Text("Continue in \(wallet.name)...")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.foreground1)
            
            Text("Accept connection request in the app")
                .font(.system(size: 14))
                .foregroundColor(.foreground3)
            
            if retryButtonShown {
                Button {
                    onListingTap(wallet)
                } label: {
                    HStack {
                        Text("Try Again")
                        Image("external_link", bundle: .module)
                    }
                }
                .buttonStyle(W3MButtonStyle())
                .padding()
            }
        }
        .padding()
        .onAppear {
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                onListingTap(wallet)
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                retryButtonShown = true
            }
        }
        .onDisappear {
            retryButtonShown = false
        }
    }
}
