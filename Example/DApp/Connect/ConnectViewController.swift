
import Foundation
import UIKit

class ConnectViewController: UIViewController {
    let uriString: String
    init(uri: String) {
        self.uriString = uri
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private let connectView: ConnectView = {
        ConnectView()
    }()
    
    override func loadView() {
        view = connectView
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        DispatchQueue.global().async { [unowned self] in
            if let qrImage = generateQRCode(from: uriString) {
                DispatchQueue.main.async {
                    connectView.qrCodeView.image = qrImage
                    connectView.copyButton.isHidden = false
                }
            }
        }
        connectView.copyButton.addTarget(self, action: #selector(copyURI), for: .touchUpInside)
        connectView.connectWalletButton.addTarget(self, action: #selector(connectWithExampleWallet), for: .touchUpInside)

        connectView.copyButton.isHidden = true
    }
    
    
    @objc func copyURI() {
        UIPasteboard.general.string = uriString
    }
    
    
    private func generateQRCode(from string: String) -> UIImage? {
        let data = string.data(using: .ascii)
        if let filter = CIFilter(name: "CIQRCodeGenerator") {
            filter.setValue(data, forKey: "inputMessage")
            if let output = filter.outputImage {
                return UIImage(ciImage: output)
            }
        }
        return nil
    }
    
    @objc func connectWithExampleWallet() {
        let url = URL(string: "walletconnectwallet:\(uriString)")!
        UIApplication.shared.open(url, options: [:]) { _ in }
    }
}
