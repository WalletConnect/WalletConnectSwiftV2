import SwiftUI

struct WalletList: View {
    @Binding var wallets: [Listing]
    @Binding var destination: Destination
    @State var retryButtonShown: Bool = false
    
    var navigateTo: (Destination) -> Void
    var onListingTap: (Listing) -> Void
    
    @State var numberOfColumns = 4
    
    @State var availableSize: CGSize = .zero
    
    var body: some View {
        ZStack {
            content()
                .animation(.default)
                .readSize { size in
                    if availableSize == size {
                        return
                    }
                    
                    numberOfColumns = Int(round(size.width / 100))
                    availableSize = size
                }
        }
    }
    
    @ViewBuilder
    private func content() -> some View {
        switch destination {
        case .welcome:
            initialList()
                .padding(.bottom, 20)
        case .viewAll:
            viewAll()
                .frame(minHeight: 250)
        case let .walletDetail(wallet):
            walletDetail(wallet)
        default:
            EmptyView()
        }
    }
    
    private func initialList() -> some View {
        ZStack {
            Spacer().frame(maxWidth: .infinity, maxHeight: 100)
            
            VStack {
                HStack {
                    ForEach(wallets.prefix(numberOfColumns)) { wallet in
                        gridItem(for: wallet)
                    }
                }
                HStack {
                    ForEach(wallets.dropFirst(numberOfColumns).prefix(max(numberOfColumns - 1, 0))) { wallet in
                        gridItem(for: wallet)
                    }
                    
                    if wallets.count > numberOfColumns * 2 {
                        viewAllItem()
                            .transform {
                                #if os(iOS)
                                    $0.onTapGesture {
                                        withAnimation {
                                            navigateTo(.viewAll)
                                        }
                                    }
                                #endif
                            }
                    }
                }
            }
            
            if wallets.isEmpty {
                ActivityIndicator(isAnimating: .constant(true))
            }
        }
    }
    
    @ViewBuilder
    private func viewAll() -> some View {
        ZStack {
            Spacer().frame(maxWidth: .infinity, maxHeight: 150)
            
            ScrollView(.vertical) {
                VStack(alignment: .leading) {
                    ForEach(Array(stride(from: 0, to: wallets.count, by: numberOfColumns)), id: \.self) { row in
                        HStack {
                            ForEach(row..<(row + numberOfColumns), id: \.self) { index in
                                if let wallet = wallets[safe: index] {
                                    gridItem(for: wallet)
                                }
                            }
                        }
                    }
                }
                .padding(.vertical)
            }
            
            LinearGradient(
                stops: [
                    .init(color: .background1, location: 0.0),
                    .init(color: .background1.opacity(0), location: 0.04),
                    .init(color: .background1.opacity(0), location: 0.96),
                    .init(color: .background1, location: 1.0),
                    
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .allowsHitTesting(false)
        }
    }
    
    @ViewBuilder
    func viewAllItem() -> some View {
        VStack {
            VStack(spacing: 3) {
                let startingIndex = (2 * numberOfColumns - 1)
                
                HStack(spacing: 3) {
                    ForEach(startingIndex..<(startingIndex + 2)) { index in
                        WalletImage(wallet: wallets[safe: index])
                            .cornerRadius(8)
                            .aspectRatio(1, contentMode: .fit)
                    }
                }
                .padding(.horizontal, 5)
                
                HStack(spacing: 3) {
                    ForEach((startingIndex + 2)..<(startingIndex + 4)) { index in
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
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(.gray.opacity(0.4), lineWidth: 1)
            )
            
            Text("View All")
                .font(.system(size: 12))
                .foregroundColor(.foreground1)
                .padding(.horizontal, 12)
                .fixedSize(horizontal: true, vertical: true)
            
            Spacer()
        }
        .frame(width: 80, height: 96)
    }
    
    @ViewBuilder
    func gridItem(for wallet: Listing) -> some View {
        VStack {
            WalletImage(wallet: wallet)
                .frame(width: 60, height: 60)
                .cornerRadius(16)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(.gray.opacity(0.4), lineWidth: 1)
                )
            
            Text(String(wallet.name.split(separator: " ").first!))
                .font(.system(size: 12))
                .foregroundColor(.foreground1)
                .multilineTextAlignment(.center)
            
            Text("RECENT")
                .opacity(0)
                .font(.system(size: 10))
                .foregroundColor(.foreground3)
                .padding(.horizontal, 12)
        }
        .frame(maxWidth: 80, maxHeight: 96)
        .transform {
            #if os(iOS)
                $0.onTapGesture {
                    withAnimation {
                        navigateTo(.walletDetail(wallet))
                    }
                }
            #endif
        }
    }
    
    private func walletDetail(_ wallet: Listing) -> some View {
        VStack(spacing: 8) {
            WalletImage(wallet: wallet, size: .large)
                .frame(width: 96, height: 96)
                .minimumScaleFactor(0.4)
            
            Text("Continue in \(wallet.name)...")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.foreground1)
            
            Text("Accept connection request in the app")
                .font(.system(size: 14))
                .foregroundColor(.foreground3)
            
            Button {
                onListingTap(wallet)
            } label: {
                HStack {
                    Text("Try Again")
                    Image(.external_link)
                }
            }
            .buttonStyle(W3MButtonStyle())
            .padding(.vertical)
            .opacity(retryButtonShown ? 1 : 0)
            .animation(.easeIn)
        }
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
