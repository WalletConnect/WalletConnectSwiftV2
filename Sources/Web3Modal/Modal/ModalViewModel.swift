
import Combine
import Foundation
import SwiftUI

enum Destination: Equatable {
    case welcome
    case viewAll
    case help
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
        case .help:
            return "What is a wallet?"
        case .getWallet:
            return "Get a wallet"
        case let .walletDetail(wallet):
            return wallet.name
        }
    }
}

final class ModalViewModel: ObservableObject {
    
    
    var isShown: Binding<Bool>
    let interactor: ModalSheetInteractor
    let projectId: String
    let uiApplicationWrapper: UIApplicationWrapper
    
    
    @Published private(set) var destinationStack: [Destination] = [.welcome]
    @Published private(set) var uri: String?
    @Published private(set) var errorMessage: String?
    @Published private(set) var wallets: [Listing] = []
    
    var destination: Destination {
        destinationStack.last!
    }
    
    private var disposeBag = Set<AnyCancellable>()
    private var deeplinkUri: String?
    
    init(
        isShown: Binding<Bool>,
        projectId: String,
        interactor: ModalSheetInteractor,
        uiApplicationWrapper: UIApplicationWrapper = .live
    ) {
        self.isShown = isShown
        self.interactor = interactor
        self.projectId = projectId
        self.uiApplicationWrapper = uiApplicationWrapper
            
        interactor.sessionSettlePublisher
            .receive(on: DispatchQueue.main)
            .sink { sessions in
                print(sessions)
                isShown.wrappedValue = false
            }
            .store(in: &disposeBag)
    }
        
    @MainActor
    func createURI() async {
        do {
            let wcUri = try await interactor.connect()
            uri = wcUri.absoluteString
            deeplinkUri = wcUri.deeplinkUri
        } catch {
            print(error)
            errorMessage = error.localizedDescription
        }
    }
        
    func navigateTo(_ destination: Destination) {
        guard self.destination != destination else { return }
        destinationStack.append(destination)
    }
    
    func onListingTap(_ listing: Listing) {
        navigateToDeepLink(
            universalLink: listing.mobile.universal ?? "",
            nativeLink: listing.mobile.native ?? ""
        )
    }
    
    func onGetWalletTap(_ listing: Listing) {
        guard
            let storeLinkString = listing.app.ios,
            let storeLink = URL(string: storeLinkString)
        else { return }
        
        uiApplicationWrapper.openURL(storeLink)
    }
    
    func onBackButton() {
        guard destinationStack.count != 1 else { return }
        _ = destinationStack.popLast()
    }
        
    func onCopyButton() {
        UIPasteboard.general.string = uri
    }

    
    @MainActor
    func fetchWallets() async {
        do {
            let wallets = try await interactor.getListings()
            // Small deliberate delay to ensure animations execute properly
            try await Task.sleep(nanoseconds: 500_000_000)
                
            withAnimation {
                self.wallets = wallets.sorted {
                    guard let lhs = $0.order else {
                        return false
                    }
                        
                    guard let rhs = $1.order else {
                        return true
                    }
                    
                    return lhs < rhs
                }
            }
        } catch {
            print(error)
        }
    }
}

private extension ModalViewModel {
    enum Errors: Error {
        case noWalletLinkFound
    }

    func navigateToDeepLink(universalLink: String, nativeLink: String) {
        do {
            let nativeUrlString = formatNativeUrlString(nativeLink)
            let universalUrlString = formatUniversalUrlString(universalLink)
            
            if let nativeUrl = nativeUrlString?.toURL() {
                uiApplicationWrapper.openURL(nativeUrl)
            } else if let universalUrl = universalUrlString?.toURL() {
                uiApplicationWrapper.openURL(universalUrl)
            } else {
                throw Errors.noWalletLinkFound
            }
        } catch {
            let alertController = UIAlertController(title: "Unable to open the app", message: nil, preferredStyle: .alert)
            alertController.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            UIApplication.shared.windows.first?.rootViewController?.present(alertController, animated: true, completion: nil)
        }
    }
        
    func isHttpUrl(url: String) -> Bool {
        return url.hasPrefix("http://") || url.hasPrefix("https://")
    }
        
    func formatNativeUrlString(_ string: String) -> String? {
        if string.isEmpty { return nil }
            
        if isHttpUrl(url: string) {
            return formatUniversalUrlString(string)
        }
            
        var safeAppUrl = string
        if !safeAppUrl.contains("://") {
            safeAppUrl = safeAppUrl.replacingOccurrences(of: "/", with: "").replacingOccurrences(of: ":", with: "")
            safeAppUrl = "\(safeAppUrl)://"
        }
        
        guard let deeplinkUri else { return nil }
            
        return "\(safeAppUrl)wc?uri=\(deeplinkUri)"
    }
        
    func formatUniversalUrlString(_ string: String) -> String? {
        if string.isEmpty { return nil }
            
        if !isHttpUrl(url: string) {
            return formatNativeUrlString(string)
        }
            
        var plainAppUrl = string
        if plainAppUrl.hasSuffix("/") {
            plainAppUrl = String(plainAppUrl.dropLast())
        }
        
        guard let deeplinkUri else { return nil }
            
        return "\(plainAppUrl)/wc?uri=\(deeplinkUri)"
    }
}

private extension String {
    func toURL() -> URL? {
        URL(string: self)
    }
}
