import SwiftUI

struct WalletList: View {
    @Binding var wallets: [Listing]
    @Binding var destination: Destination
    @State var retryButtonShown: Bool = false
    
    var navigateTo: (Destination) -> Void
    var onListingTap: (Listing) -> Void
    
    @State var numberOfColumns = 4
    
    var body: some View {
        content()
            .readSize { size in
                if numberOfColumns == 4 {
                    numberOfColumns = Int(round(size.width / 140))
                }
                
                return
            }
            .id(numberOfColumns)
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
            Spacer().frame(height: 200)
            
            VStack {
                HStack {
                    ForEach(0..<numberOfColumns) { index in
                        gridItem(for: index)
                    }
                }
                HStack {
                    ForEach(numberOfColumns..<(2 * numberOfColumns - 1)) { index in
                        gridItem(for: index)
                    }
                    
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
    }
    
    @ViewBuilder
    private func viewAll() -> some View {
        ZStack {
            Spacer().frame(height: 450)
            
            ScrollView(.vertical) {
                VStack(alignment: .leading) {
                    ForEach(Array(stride(from: 0, to: wallets.count, by: numberOfColumns)), id: \.self) { row in
                        HStack {
                            ForEach(row..<(row + numberOfColumns), id: \.self) { index in
                                if wallets.indices.contains(index) {
                                    gridItem(for: index)
                                }
                            }
                        }
                    }
                }
                .padding(.top)
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
        .transform {
            #if os(iOS)
                $0.onTapGesture {
                    guard let wallet else { return }
                    
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
                .frame(maxWidth: 96, maxHeight: 96)
            
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
                    Image("external_link", bundle: .module)
                }
            }
            .buttonStyle(W3MButtonStyle())
            .padding()
            .opacity(retryButtonShown ? 1 : 0)
            .animation(.easeIn)
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
