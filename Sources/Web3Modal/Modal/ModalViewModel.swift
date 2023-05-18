
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
        private var disposeBag = Set<AnyCancellable>()
        private let interactor: Interactor
        private let projectId: String
        
        @Published var isShown: Binding<Bool>
        
        @Published var uri: String?
        @Published var destination: Destination = .qr
        @Published var errorMessage: String?
        @Published var wallets: [Listing] = []
        
        init(isShown: Binding<Bool>, projectId: String, interactor: Interactor) {
            self.isShown = isShown
            self.interactor = interactor
            self.projectId = projectId
            
            interactor.sessionsPublisher
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
                uri = try await interactor.connect().absoluteString
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
        
        func imageUrl(for listing: Listing) -> URL? {
            let urlString = "https://explorer-api.walletconnect.com/v3/logo/md/\(listing.imageId)?projectId=\(projectId)"
            
            return URL(string: urlString)
        }
    }
}
