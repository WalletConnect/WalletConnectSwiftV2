
import Combine
import Foundation
import SwiftUI

enum Destination: Equatable {
    case welcome
    case viewAll
    case qr
    case walletDetail(Wallet)
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
    @Published private(set) var wallets: [Wallet] = []
        
    @Published var searchTerm: String = ""
    
    @Published var toast: Toast?
    
    @Published private(set) var isThereMoreWallets: Bool = true
    private var maxPage = Int.max
    private var currentPage: Int = 0
    
    var destination: Destination {
        destinationStack.last!
    }
    
    var filteredWallets: [Wallet] {
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
            let wcUri = try await interactor.createPairingAndConnect()
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
    
    func onWalletTap(_ wallet: Wallet) {
        setLastTimeUsed(wallet.id)
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
        let entries = 40
        
        do {
            guard currentPage <= maxPage else {
                return
            }
            
            currentPage += 1
            
            if currentPage == maxPage {
                isThereMoreWallets = false
            }
        
            let (total, wallets) = try await interactor.getWallets(page: currentPage, entries: entries)
            maxPage = Int(Double(total / entries).rounded(.up))

            // Small deliberate delay to ensure animations execute properly
            try await Task.sleep(nanoseconds: 500_000_000)
            
            loadRecentWallets()
            checkWhetherInstalled(wallets: wallets)
            
            self.wallets.append(contentsOf: wallets
                .sortByOrder()
                .sortByInstalled()
            )
        } catch {
            toast = Toast(style: .error, message: error.localizedDescription)
        }
    }
}

// MARK: - Sorting and filtering

private extension Array where Element: Wallet {
    func sortByOrder() -> [Wallet] {
        sorted {
            $0.order < $1.order
        }
    }
    
    func sortByInstalled() -> [Wallet] {
        sorted { lhs, rhs in
            if lhs.isInstalled, !rhs.isInstalled {
                return true
            }
            
            if !lhs.isInstalled, rhs.isInstalled {
                return false
            }
            
            return false
        }
    }
    
    func sortByRecent() -> [Wallet] {
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
    
    func filter(searchTerm: String) -> [Wallet] {
        if searchTerm.isEmpty { return self }
        
        return filter {
            $0.name.lowercased().contains(searchTerm.lowercased())
        }
    }
}

// MARK: - Recent & Installed Wallets

private extension ModalViewModel {
    func checkWhetherInstalled(wallets: [Wallet]) {
        guard let schemes = Bundle.main.object(forInfoDictionaryKey: "LSApplicationQueriesSchemes") as? [String] else {
            return
        }
        
        wallets.forEach {
            if
                let walletScheme = $0.mobileLink,
                !walletScheme.isEmpty,
                schemes.contains(walletScheme.replacingOccurrences(of: "://", with: ""))
            {
                $0.isInstalled = uiApplicationWrapper.canOpenURL(URL(string: walletScheme)!)
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
    func openAppstore(wallet: Wallet)
    func navigateToDeepLink(wallet: Wallet, preferBrowser: Bool)
}

extension ModalViewModel: WalletDeeplinkHandler {
    func openAppstore(wallet: Wallet) {
        guard
            let storeLinkString = wallet.appStore,
            let storeLink = URL(string: storeLinkString)
        else { return }
        
        uiApplicationWrapper.openURL(storeLink, nil)
    }
    
    func navigateToDeepLink(wallet: Wallet, preferBrowser: Bool) {
        do {
            let nativeScheme = preferBrowser ? wallet.webappLink : wallet.mobileLink
            let nativeUrlString = try formatNativeUrlString(nativeScheme)
            
            if let nativeUrl = nativeUrlString?.toURL() {
                uiApplicationWrapper.openURL(nativeUrl) { success in
                    if !success {
                        self.toast = Toast(style: .error, message: DeeplinkErrors.failedToOpen.localizedDescription)
                    }
                }
            } else {
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
