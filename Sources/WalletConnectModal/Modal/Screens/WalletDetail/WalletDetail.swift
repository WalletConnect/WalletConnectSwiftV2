import SwiftUI

struct WalletDetail: View {
    @Environment(\.verticalSizeClass) var verticalSizeClass
    
    @ObservedObject var viewModel: WalletDetailViewModel
    
    @State var retryShown: Bool = false
    
    var body: some View {
        VStack {
            if viewModel.showToggle {
                Web3ModalPicker(
                    WalletDetailViewModel.Platform.allCases,
                    selection: viewModel.preferredPlatform
                ) { item in
                        
                    HStack {
                        switch item {
                        case .native:
                            Image(systemName: "iphone")
                        case .browser:
                            Image(systemName: "safari")
                        }
                        Text(item.rawValue.capitalized)
                    }
                    .font(.system(size: 14).weight(.semibold))
                    .multilineTextAlignment(.center)
                    .foregroundColor(viewModel.preferredPlatform == item ? .foreground1 : .foreground2)
                    .frame(maxWidth: .infinity)
                    .contentShape(Rectangle())
                    .padding(.horizontal, 8)
                    .padding(.vertical, 8)
                    .onTapGesture {
                        withAnimation(.easeInOut(duration: 0.15)) {
                            viewModel.preferredPlatform = item
                        }
                    }
                }
                .pickerBackgroundColor(.background2)
                .cornerRadius(20)
                .borderWidth(1)
                .borderColor(.thinOverlay)
                .accentColor(.thinOverlay)
                .frame(maxWidth: 250)
                .padding()
            }
            
            content()
                .onAppear {
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        viewModel.handle(.onAppear)
                    }
                    
                    if verticalSizeClass == .compact {
                        retryShown = true
                    } else {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                            withAnimation {
                                retryShown = true
                            }
                        }
                    }
                }
                .onDisappear {
                    retryShown = false
                }
                .animation(.easeInOut, value: viewModel.preferredPlatform)
        }
    }
    
    @ViewBuilder
    func content() -> some View {
        if verticalSizeClass == .compact {
            HStack(alignment: .top) {
                walletImage()
                    .padding(.horizontal, 80)
                    .layoutPriority(1)
                
                VStack(spacing: 15) {
                    if retryShown {
                        retrySection()
                    }
                    
                    VStack {
                        Divider()
                        appStoreRow()
                    }
                    .opacity(viewModel.preferredPlatform != .native ? 0 : 1)
                }
                .padding(.horizontal, 20)
            }
            .padding(.bottom, 40)
        } else {
            VStack(spacing: 0) {
                walletImage()
                    .padding(.vertical, 40)
                
                VStack(spacing: 15) {
                    if retryShown {
                        retrySection()
                            .frame(maxWidth: .infinity)
                            .padding(.top, 15)
                    }
                    
                    VStack {
                        Divider()
                        appStoreRow()
                    }
                    .opacity(viewModel.preferredPlatform != .native ? 0 : 1)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 40)
                .background(Color.background2)
            }
        }
    }
    
    func walletImage() -> some View {
        VStack(spacing: 20) {
            WalletImage(wallet: viewModel.wallet, size: .large)
                .frame(width: 96, height: 96)
                .cornerRadius(24)
                .overlay(
                    RoundedRectangle(cornerRadius: 24)
                        .stroke(.gray.opacity(0.4), lineWidth: 1)
                )
            
            Text("Continue in \(viewModel.wallet.name)...")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.foreground1)
        }
    }
    
    func retrySection() -> some View {
        VStack(spacing: 15) {
            Text("You can try opening \(viewModel.wallet.name) again \((viewModel.hasNativeLink && viewModel.showUniversalLink) ? "or try using a Universal Link instead" : "")")
                .font(.system(size: 14, weight: .medium))
                .multilineTextAlignment(.center)
                .foregroundColor(.foreground2)
                .fixedSize(horizontal: false, vertical: true)
            
            HStack {
                Button {
                    viewModel.handle(.didTapTryAgain)
                } label: {
                    Text("Try Again")
                }
                .buttonStyle(WCMAccentButtonStyle())
                
                if viewModel.showUniversalLink {
                    Button {
                        viewModel.handle(.didTapUniversalLink)
                    } label: {
                        Text("Universal link")
                    }
                    .buttonStyle(WCMAccentButtonStyle())
                }
            }
        }
        .frame(height: 100)
    }
    
    func appStoreRow() -> some View {
        HStack(spacing: 0) {
            HStack(spacing: 10) {
                WalletImage(wallet: viewModel.wallet, size: .small)
                    .frame(width: 28, height: 28)
                    .cornerRadius(8)
                
                Text("Get \(viewModel.wallet.name)")
                    .font(.system(size: 16).weight(.semibold))
                    .foregroundColor(.foreground1)
            }
            
            Spacer()
            
            HStack(spacing: 3) {
                Text("App Store")
                    .foregroundColor(.foreground2)
                    .font(.system(size: 14).weight(.semibold))
                
                Image(systemName: "chevron.right")
                    .foregroundColor(.foreground2)
            }
        }
        .onTapGesture {
            viewModel.handle(.didTapAppStore)
        }
    }
}
