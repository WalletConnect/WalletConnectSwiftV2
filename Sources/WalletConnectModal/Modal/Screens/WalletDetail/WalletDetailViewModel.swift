import Foundation

final class WalletDetailViewModel: ObservableObject {
    enum Platform: String, CaseIterable, Identifiable {
        case native
        case browser
        
        var id: Self { self }
    }
    
    enum Event {
        case onAppear
        case didTapUniversalLink
        case didTapTryAgain
        case didTapAppStore
    }
    
    let wallet: Wallet
    let deeplinkHandler: WalletDeeplinkHandler
    
    @Published var preferredPlatform: Platform = .native
    
    var showToggle: Bool { wallet.webappLink != nil && wallet.appStore != nil }
    var showUniversalLink: Bool { preferredPlatform == .native && wallet.mobileLink?.isEmpty == false }
    var hasNativeLink: Bool { wallet.mobileLink?.isEmpty == false }
    
    init(
        wallet: Wallet,
        deeplinkHandler: WalletDeeplinkHandler
    ) {
        self.wallet = wallet
        self.deeplinkHandler = deeplinkHandler
        preferredPlatform = wallet.appStore != nil ? .native : .browser
    }
    
    func handle(_ event: Event) {
        switch event {
        case .onAppear:
            deeplinkHandler.navigateToDeepLink(
                wallet: wallet,
                preferUniversal: true,
                preferBrowser: preferredPlatform == .browser
            )
            
        case .didTapUniversalLink:
            deeplinkHandler.navigateToDeepLink(
                wallet: wallet,
                preferUniversal: true,
                preferBrowser: preferredPlatform == .browser
            )
            
        case .didTapTryAgain:
            deeplinkHandler.navigateToDeepLink(
                wallet: wallet,
                preferUniversal: false,
                preferBrowser: preferredPlatform == .browser
            )

        case .didTapAppStore:
            deeplinkHandler.openAppstore(wallet: wallet)
        }
    }
}
