import UIKit
import SwiftUI
import Auth
import WalletConnectRelay

final class AuthViewController: UIHostingController<AuthView> {

    init() {
        super.init(rootView: AuthView())
        rootView.didPressConnect = { [weak self] in
            self?.connect()
        }
    }

    private func connect() {
        print("creating QR code")
        let mockURI = "wc:7f6e504bfad60b485450578e05678ed3e8e8c4751d3c6160be17160d63ec90f9@2?relay-protocol=iridium&symKey=587d5484ce2a2a6ee3ba1962fdd7e8588e06200c46823bd18fbd67def96ad303"
        if let qrCode = generateQRCode(from: mockURI) {
            print("setting QR code")
            rootView.qrCode = qrCode
        }
    }

    private func generateQRCode(from string: String) -> UIImage? {
        let data = string.data(using: .ascii)
        if let filter = CIFilter(name: "CIQRCodeGenerator") {
            filter.setValue(data, forKey: "inputMessage")
            let transform = CGAffineTransform(scaleX: 4, y: 4)
            if let output = filter.outputImage?.transformed(by: transform) {
                return UIImage(ciImage: output)
            }
        }
        return nil
    }

    private func createAuthClient() -> AuthClient {
        let metadata = AppMetadata(
            name: "Swift Dapp",
            description: "a description",
            url: "wallet.connect",
            icons: ["https://avatars.githubusercontent.com/u/37784886"])
        let account = Account(chainIdentifier: "eip155:1", address: "0x3627523167367216556273151")!
        let client = AuthClientFactory.create(metadata: metadata, account: account, relayClient: Relay.instance)
        return client
    }

    @MainActor required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
