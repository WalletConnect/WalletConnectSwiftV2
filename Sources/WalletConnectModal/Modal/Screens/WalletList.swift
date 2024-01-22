import SwiftUI

struct WalletList: View {
    
    @Binding var destination: Destination
    
    @ObservedObject var viewModel: ModalViewModel
    
    var navigateTo: (Destination) -> Void
    var onWalletTap: (Wallet) -> Void
    
    @State var numberOfColumns = 4
    @State var availableSize: CGSize = .zero
    
    init(
        destination: Binding<Destination>,
        viewModel: ModalViewModel,
        navigateTo: @escaping (Destination) -> Void, 
        onWalletTap: @escaping (Wallet) -> Void, 
        numberOfColumns: Int = 4, 
        availableSize: CGSize = .zero, 
        infiniteScrollLoading: Bool = false
    ) {
        self._destination = destination
        self.viewModel = viewModel
        self.navigateTo = navigateTo
        self.onWalletTap = onWalletTap
        self.numberOfColumns = numberOfColumns
        self.availableSize = availableSize
        self.infiniteScrollLoading = infiniteScrollLoading
        
        if #available(iOS 14.0, *) {
            // iOS 14 doesn't have extra separators below the list by default.
        } else {
            // To remove only extra separators below the list:
            UITableView.appearance(whenContainedInInstancesOf: [WalletConnectModalSheetController.self]).tableFooterView = UIView()
        }

        // To remove all separators including the actual ones:
        UITableView.appearance(whenContainedInInstancesOf: [WalletConnectModalSheetController.self]).separatorStyle = .none
    }
    
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
                .animation(nil)
        default:
            EmptyView()
        }
    }
    
    private func initialList() -> some View {
        ZStack {
            Spacer().frame(maxWidth: .infinity, maxHeight: 100)
            
            VStack {
                HStack {
                    ForEach(viewModel.filteredWallets.prefix(numberOfColumns)) { wallet in
                        gridItem(for: wallet)
                    }
                }
                HStack {
                    ForEach(viewModel.filteredWallets.dropFirst(numberOfColumns).prefix(max(numberOfColumns - 1, 0))) { wallet in
                        gridItem(for: wallet)
                    }
                    
                    if viewModel.filteredWallets.count > numberOfColumns * 2 {
                        viewAllItem()
                            .onTapGestureBackported {
                                withAnimation {
                                    navigateTo(.viewAll)
                                }
                            }
                    }
                }
            }
            
            if viewModel.filteredWallets.isEmpty {
                ActivityIndicator(isAnimating: .constant(true))
            }
        }
    }
    
    @State var infiniteScrollLoading = false
    
    @ViewBuilder
    private func viewAll() -> some View {
        ZStack {
            Spacer().frame(maxWidth: .infinity, maxHeight: 150)
            
            List {
                ForEach(Array(stride(from: 0, to: viewModel.filteredWallets.count, by: numberOfColumns)), id: \.self) { row in
                    HStack {
                        ForEach(row ..< (row + numberOfColumns), id: \.self) { index in
                            if let wallet = viewModel.filteredWallets[safe: index] {
                                gridItem(for: wallet)
                            }
                        }
                    }
                }
                .listRowInsets(EdgeInsets(top: 0, leading: 24, bottom: 8, trailing: 24))
                .transform {
                    if #available(iOS 15.0, *) {
                        $0.listRowSeparator(.hidden)
                    }
                }
                
                if viewModel.isThereMoreWallets {
                    Color.clear.frame(height: 100)
                        .onAppear {
                            Task {
                                await viewModel.fetchWallets()
                            }
                        }
                        .transform {
                            if #available(iOS 15.0, *) {
                                $0.listRowSeparator(.hidden)
                            }
                        }
                }
            }
            .listStyle(.plain)
                
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
                let viewAllWalletsFirstRow = viewModel.filteredWallets.dropFirst(2 * numberOfColumns - 1).prefix(2)
                
                HStack(spacing: 3) {
                    ForEach(viewAllWalletsFirstRow) { wallet in
                        WalletImage(wallet: wallet)
                            .cornerRadius(8)
                            .aspectRatio(1, contentMode: .fit)
                    }
                }
                .padding(.horizontal, 5)
                
                let viewAllWalletsSecondRow = viewModel.filteredWallets.dropFirst(2 * numberOfColumns + 1).prefix(2)
                
                HStack(spacing: 3) {
                    ForEach(viewAllWalletsSecondRow) { wallet in
                        WalletImage(wallet: wallet)
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
    func gridItem(for wallet: Wallet) -> some View {
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
            
            Text(wallet.lastTimeUsed != nil ? "RECENT" : "INSTALLED")
                .opacity(wallet.lastTimeUsed != nil || wallet.isInstalled ? 1 : 0)
                .font(.system(size: 10))
                .foregroundColor(.foreground3)
                .padding(.horizontal, 12)
        }
        .frame(maxWidth: 80, maxHeight: 96)
        .onTapGestureBackported {
            withAnimation {
                navigateTo(.walletDetail(wallet))
                
                // Small delay to let detail screen present before actually deeplinking
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    onWalletTap(wallet)
                }
            }
        }
    }
}
