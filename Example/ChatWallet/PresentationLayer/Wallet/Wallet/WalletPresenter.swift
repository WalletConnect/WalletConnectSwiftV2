import UIKit
import Combine
import Auth

final class WalletPresenter: ObservableObject {
    private var disposeBag = Set<AnyCancellable>()
    
    @Published var pastPairingUriText = "Paste pairing URI"
    @Published var scanPairingUriText = "Scan pairing URI"
}

// MARK: - SceneViewModel
extension WalletPresenter: SceneViewModel {
    var sceneTitle: String? {
        return "Wallet"
    }

    var largeTitleDisplayMode: UINavigationItem.LargeTitleDisplayMode {
        return .always
    }
}
