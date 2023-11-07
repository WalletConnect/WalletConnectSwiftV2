import UIKit
import Combine

import WalletConnectSign

final class NewPairingPresenter: ObservableObject {
    @Published var qrCodeImageData: Data?
    
    private let interactor: NewPairingInteractor
    private let router: NewPairingRouter

    var walletConnectUri: WalletConnectURI
    
    private var subscriptions = Set<AnyCancellable>()

    init(
        interactor: NewPairingInteractor,
        router: NewPairingRouter,
        walletConnectUri: WalletConnectURI
    ) {
        self.interactor = interactor
        self.router = router
        self.walletConnectUri = walletConnectUri
    }
    
    func onAppear() {
        generateQR()
    }
    
    func connectWallet() {
        let url = URL(string: "walletapp://wc?uri=\(walletConnectUri.deeplinkUri.removingPercentEncoding!)")!
        DispatchQueue.main.async {
            UIApplication.shared.open(url)
        }
        router.dismiss()
    }
    
    func copyUri() {
        UIPasteboard.general.string = walletConnectUri.absoluteString
    }
}

// MARK: - Private functions
extension NewPairingPresenter {
    private func generateQR() {
        Task { @MainActor in
            let qrCodeImage = QRCodeGenerator.generateQRCode(from: walletConnectUri.absoluteString)
            qrCodeImageData = qrCodeImage.pngData()
        }
    }
}

// MARK: - SceneViewModel
extension NewPairingPresenter: SceneViewModel {}
