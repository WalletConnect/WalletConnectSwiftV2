
import Combine
import Foundation
import SwiftUI

extension ModalSheet {
    enum Destination: String, CaseIterable {
        case wallets
        case help
        case qr
        
        var contentTitle: String {
            switch self {
            case .wallets:
                return "Connect your wallet"
            case .qr:
                return "Scan the code"
            case .help:
                return "What is a wallet?"
            }
        }
    }
    
    final class ModalViewModel: ObservableObject {
        @Published private(set) var isShown: Binding<Bool>
        private let projectId: String
        private let interactor: ModalSheetInteractor
        private let uiApplicationWrapper: UIApplicationWrapper
                
        private var disposeBag = Set<AnyCancellable>()
        private var deeplinkUri: String?
        
        @Published private(set) var uri: String?
        @Published private(set) var destination: Destination = .wallets
        @Published private(set) var errorMessage: String?
        @Published private(set) var wallets: [Listing] = []
        
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
        func fetchWallets() async {
            do {
                let wallets = try await interactor.getListings()
                // Small deliberate delay to ensure animations execute properly
                try await Task.sleep(nanoseconds: 500_000_000)
                
                withAnimation {
                    self.wallets = wallets.sorted { $0.order < $1.order }
                }
            } catch {
                print(error)
                errorMessage = error.localizedDescription
            }
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
            self.destination = destination
        }
        
        func onBackButton() {
            destination = .wallets
        }
        
        func onCopyButton() {
            UIPasteboard.general.string = uri
        }
        
        func onWalletTapped(index: Int) {
            guard let wallet = wallets[safe: index] else { return }
            
            navigateToDeepLink(
                universalLink: wallet.mobile.universal ?? "",
                nativeLink: wallet.mobile.native ?? ""
            )
        }
        
        func imageUrl(for listing: Listing?) -> URL? {
            guard let listing = listing else { return nil }
            
            let urlString = "https://explorer-api.walletconnect.com/v3/logo/md/\(listing.imageId)?projectId=\(projectId)"
            
            return URL(string: urlString)
        }
    }
}

private extension ModalSheet.ModalViewModel {
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
