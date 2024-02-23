
import Combine
import Foundation
import SwiftUI

enum Destination: Equatable {
    case welcome
    case viewAll
    case qr
    case walletDetail(Listing)
    case getWallet
        
    var contentTitle: String {
        switch self {
        case .welcome:
            return "Connect your wallet"
        case .viewAll:
            return "View all"
        case .qr:
            return "Scan the code"
        case .getWallet:
            return "Get a wallet"
        case let .walletDetail(wallet):
            return wallet.name
        }
    }
    
    var hasSearch: Bool {
        if case .viewAll = self {
            return true
        }
        
        return false
    }
}

final class ModalViewModel: ObservableObject {
    var isShown: Binding<Bool>
    let interactor: ModalSheetInteractor
    let uiApplicationWrapper: UIApplicationWrapper
    let recentWalletStorage: RecentWalletsStorage
    
    @Published private(set) var destinationStack: [Destination] = [.welcome]
    @Published private(set) var uri: String?
    @Published private(set) var wallets: [Listing] = []
    
    @Published var searchTerm: String = ""
    
    @Published var toast: Toast?
    
    var destination: Destination {
        destinationStack.last!
    }
    
    var filteredWallets: [Listing] {
        wallets
            .sortByRecent()
            .filter(searchTerm: searchTerm)
    }
    
    private var disposeBag = Set<AnyCancellable>()
    private var deeplinkUri: String?
    
    init(
        isShown: Binding<Bool>,
        interactor: ModalSheetInteractor,
        uiApplicationWrapper: UIApplicationWrapper = .live,
        recentWalletStorage: RecentWalletsStorage = RecentWalletsStorage()
    ) {
        self.isShown = isShown
        self.interactor = interactor
        self.uiApplicationWrapper = uiApplicationWrapper
        self.recentWalletStorage = recentWalletStorage
            
        interactor.sessionSettlePublisher
            .receive(on: DispatchQueue.main)
            .sink { sessions in
                print(sessions)
                isShown.wrappedValue = false
                self.toast = Toast(style: .success, message: "Session estabilished", duration: 5)
            }
            .store(in: &disposeBag)
        
        interactor.sessionRejectionPublisher
            .receive(on: DispatchQueue.main)
            .sink { _, reason in
                
                print(reason)
                self.toast = Toast(style: .error, message: reason.message)
                
                Task {
                    await self.createURI()
                }
            }
            .store(in: &disposeBag)
    }
        
    @MainActor
    func createURI() async {
        do {
            guard let wcUri = try await interactor.createPairingAndConnect() else {
                toast = Toast(style: .error, message: "Failed to create pairing")
                return
            }
            uri = wcUri.absoluteString
            deeplinkUri = wcUri.deeplinkUri
        } catch {
            print(error)
            toast = Toast(style: .error, message: error.localizedDescription)
        }
    }
        
    func navigateTo(_ destination: Destination) {
        guard self.destination != destination else { return }
        destinationStack.append(destination)
    }
    
    func navigateToExternalLink(_ url: URL) {
        uiApplicationWrapper.openURL(url, nil)
    }
    
    func onListingTap(_ listing: Listing) {
        setLastTimeUsed(listing.id)
    }
    
    func onBackButton() {
        guard destinationStack.count != 1 else { return }
        
        withAnimation {
            _ = destinationStack.popLast()
        }
        
        if destinationStack.last?.hasSearch == false {
            searchTerm = ""
        }
    }
        
    func onCopyButton() {
        guard let uri else {
            toast = Toast(style: .error, message: "No uri found")
            return
        }
        
        #if os(iOS)
        
        UIPasteboard.general.string = uri
        
        #elseif canImport(AppKit)
        
        NSPasteboard.general.setString(uri, forType: .string)
        
        #endif
        
        toast = Toast(style: .info, message: "URI copied into clipboard")
    }
    
    func onCloseButton() {
        withAnimation {
            isShown.wrappedValue = false
        }
    }
    
    @MainActor
    func fetchWallets() async {
        do {
            let wallets = try await interactor.getListings()
            // Small deliberate delay to ensure animations execute properly
            try await Task.sleep(nanoseconds: 500_000_000)
                
            loadRecentWallets()
            checkWhetherInstalled(wallets: wallets)
            
            self.wallets = wallets
                .sortByOrder()
                .sortByInstalled()
        } catch {
            toast = Toast(style: .error, message: error.localizedDescription)
        }
    }
}

// MARK: - Sorting and filtering

private extension Array where Element: Listing {
    func sortByOrder() -> [Listing] {
        sorted {
            guard let lhs = $0.order else {
                return false
            }
            
            guard let rhs = $1.order else {
                return true
            }
            
            return lhs < rhs
        }
    }
    
    func sortByInstalled() -> [Listing] {
        sorted { lhs, rhs in
            if lhs.installed, !rhs.installed {
                return true
            }
            
            if !lhs.installed, rhs.installed {
                return false
            }
            
            return false
        }
    }
    
    func sortByRecent() -> [Listing] {
        sorted { lhs, rhs in
            guard let lhsLastTimeUsed = lhs.lastTimeUsed else {
                return false
            }
            
            guard let rhsLastTimeUsed = rhs.lastTimeUsed else {
                return true
            }
            
            return lhsLastTimeUsed > rhsLastTimeUsed
        }
    }
    
    func filter(searchTerm: String) -> [Listing] {
        if searchTerm.isEmpty { return self }
        
        return filter {
            $0.name.lowercased().contains(searchTerm.lowercased())
        }
    }
}

// MARK: - Recent & Installed Wallets

private extension ModalViewModel {
    func checkWhetherInstalled(wallets: [Listing]) {
        guard let schemes = Bundle.main.object(forInfoDictionaryKey: "LSApplicationQueriesSchemes") as? [String] else {
            return
        }
        
        wallets.forEach {
            if
                let walletScheme = $0.mobile.native,
                !walletScheme.isEmpty,
                schemes.contains(walletScheme.replacingOccurrences(of: "://", with: ""))
            {
                $0.installed = uiApplicationWrapper.canOpenURL(URL(string: walletScheme)!)
            }
        }
    }
    
    func loadRecentWallets() {
        recentWalletStorage.recentWallets.forEach { wallet in
            guard let lastTimeUsed = wallet.lastTimeUsed else { return }
            setLastTimeUsed(wallet.id, date: lastTimeUsed)
        }
    }
    
    func setLastTimeUsed(_ id: String, date: Date = Date()) {
        wallets.first {
            $0.id == id
        }?.lastTimeUsed = date
        recentWalletStorage.recentWallets = wallets
    }
}

// MARK: - Deeplinking

protocol WalletDeeplinkHandler {
    func openAppstore(wallet: Listing)
    func navigateToDeepLink(wallet: Listing, preferUniversal: Bool, preferBrowser: Bool)
}

extension ModalViewModel: WalletDeeplinkHandler {
    func openAppstore(wallet: Listing) {
        guard
            let storeLinkString = wallet.app.ios,
            let storeLink = URL(string: storeLinkString)
        else { return }
        
        uiApplicationWrapper.openURL(storeLink, nil)
    }
    
    func navigateToDeepLink(wallet: Listing, preferUniversal: Bool, preferBrowser: Bool) {
        do {
            let nativeScheme = preferBrowser ? nil : wallet.mobile.native
            let universalScheme = preferBrowser ? wallet.desktop.universal : wallet.mobile.universal
            
            let nativeUrlString = try formatNativeUrlString(nativeScheme)
            let universalUrlString = try formatUniversalUrlString(universalScheme)
            
            if let universalUrl = universalUrlString?.toURL(), preferUniversal {
                uiApplicationWrapper.openURL(universalUrl) { success in
                    if !success {
                        self.toast = Toast(style: .error, message: DeeplinkErrors.failedToOpen.localizedDescription)
                    }
                }
            } 
            else if let nativeUrl = nativeUrlString?.toURL() {
                uiApplicationWrapper.openURL(nativeUrl) { success in
                    if !success {
                        self.toast = Toast(style: .error, message: DeeplinkErrors.failedToOpen.localizedDescription)
                    }
                }
            }
            else {
                throw DeeplinkErrors.noWalletLinkFound
            }
        } catch {
            toast = Toast(style: .error, message: error.localizedDescription)
        }
    }
}

private extension ModalViewModel {
    enum DeeplinkErrors: LocalizedError {
        case noWalletLinkFound
        case uriNotCreated
        case failedToOpen
        
        var errorDescription: String? {
            switch self {
            case .noWalletLinkFound:
                return NSLocalizedString("No valid link for opening given wallet found", comment: "")
            case .uriNotCreated:
                return NSLocalizedString("Couldn't generate link due to missing connection URI", comment: "")
            case .failedToOpen:
                return NSLocalizedString("Given link couldn't be opened", comment: "")
            }
        }
    }
        
    func isHttpUrl(url: String) -> Bool {
        return url.hasPrefix("http://") || url.hasPrefix("https://")
    }
        
    func formatNativeUrlString(_ string: String?) throws -> String? {
        guard let string = string, !string.isEmpty else { return nil }
            
        if isHttpUrl(url: string) {
            return try formatUniversalUrlString(string)
        }
            
        var safeAppUrl = string
        if !safeAppUrl.contains("://") {
            safeAppUrl = safeAppUrl.replacingOccurrences(of: "/", with: "").replacingOccurrences(of: ":", with: "")
            safeAppUrl = "\(safeAppUrl)://"
        }
        
        guard let deeplinkUri else {
            throw DeeplinkErrors.uriNotCreated
        }
            
        return "\(safeAppUrl)wc?uri=\(deeplinkUri)"
    }
        
    func formatUniversalUrlString(_ string: String?) throws -> String? {
        guard let string = string, !string.isEmpty else { return nil }
            
        if !isHttpUrl(url: string) {
            return try formatNativeUrlString(string)
        }
            
        var plainAppUrl = string
        if plainAppUrl.hasSuffix("/") {
            plainAppUrl = String(plainAppUrl.dropLast())
        }
        
        guard let deeplinkUri else {
            throw DeeplinkErrors.uriNotCreated
        }
            
        return "\(plainAppUrl)/wc?uri=\(deeplinkUri)"
    }
}

private extension String {
    func toURL() -> URL? {
        URL(string: self)
    }
}
