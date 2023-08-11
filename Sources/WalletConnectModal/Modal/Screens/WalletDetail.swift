import SwiftUI

struct WalletDetail: View {
    enum Platform: CustomStringConvertible, CaseIterable, Identifiable {
        case native
        case browser
        
        var id: Self { self }
        
        var description: String {

            switch self {
            case .native:
                return "Native"
            case .browser:
                return "Browser"
            }
        }
    }
    
    @Environment(\.verticalSizeClass) var verticalSizeClass
    
    @State var wallet: Listing
    @State var retryShown: Bool = false
    
    var showToggle: Bool { wallet.app.browser != nil && wallet.app.ios != nil }
    @State var preferredPlatform: Platform = .native
    
    let deeplink: (Listing) -> Void
    var deeplinkUniversal: (Listing) -> Void
    var openAppStore: (Listing) -> Void
    
    var body: some View {
        VStack {
            if showToggle {
                Picker("Preferred platform", selection: $preferredPlatform) {
                    ForEach(Platform.allCases) { option in
                        Text(String(describing: option))
                    }
                }
                .pickerStyle(.segmented)
                .padding()
            }
            
            content()
                .onAppear {
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
                .animation(.easeInOut, value: preferredPlatform)
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
                    
                    if preferredPlatform == .native {
                        Divider()
                        appStoreRow()
                    }
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
                    .frame(height: preferredPlatform != .native ? 0 : nil)
                    .opacity(preferredPlatform != .native ? 0 : 1)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 40)
                .background(Color.background2)
            }
        }
    }
    
    func walletImage() -> some View {
        VStack(spacing: 20) {
            WalletImage(wallet: wallet, size: .large)
                .frame(width: 96, height: 96)
                .cornerRadius(24)
                .overlay(
                    RoundedRectangle(cornerRadius: 24)
                        .stroke(.gray.opacity(0.4), lineWidth: 1)
                )
            
            Text("Continue in \(wallet.name)...")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.foreground1)
        }
    }
    
    func retrySection() -> some View {
        VStack(spacing: 15) {
            let hasUniversalLink = wallet.mobile.universal?.isEmpty == false
            let hasNativeLink = wallet.mobile.native?.isEmpty == false
            
            Text("You can try opening \(wallet.name) again \((hasNativeLink && hasUniversalLink) ? "or try using a Universal Link instead" : "")")
                .font(.system(size: 14, weight: .medium))
                .multilineTextAlignment(.center)
                .foregroundColor(.foreground2)
                .fixedSize(horizontal: false, vertical: true)
            
            HStack {
                Button {
                    deeplink(wallet)
                } label: {
                    Text("Try Again")
                }
                .buttonStyle(WCMAccentButtonStyle())
                
                if hasUniversalLink {
                    Button {
                        deeplinkUniversal(wallet)
                    } label: {
                        Text("Universal link")
                    }
                    .buttonStyle(WCMAccentButtonStyle())
                }
            }
        }
    }
    
    func appStoreRow() -> some View {
        HStack(spacing: 0) {
            HStack(spacing: 10) {
                WalletImage(wallet: wallet, size: .small)
                    .frame(width: 28, height: 28)
                    .cornerRadius(8)
                
                Text("Get \(wallet.name)")
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
            openAppStore(wallet)
        }
    }
}
