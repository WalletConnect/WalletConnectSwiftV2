
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
    private var disposeBag = Set<AnyCancellable>()
    let interactor: Interactor
    let projectId: String
    
    @Published var destinationStack: [Destination] = [.welcome]
    
    var destination: Destination {
        destinationStack.last!
    }
    
    @Published var isShown: Binding<Bool>
        
    @Published var uri: String?
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
    func createURI() async {
        do {
            uri = try await interactor.connect().absoluteString
        } catch {
            print(error)
            errorMessage = error.localizedDescription
        }
    }
        
    func navigateTo(_ destination: Destination) {
        guard self.destination != destination else { return }
        destinationStack.append(destination)
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
