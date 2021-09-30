import UIKit

final class ProposerViewController: UIViewController {
    
    private var currentURI: String?
    
    private let proposerView: ProposerView = {
        ProposerView()
    }()
    
    override func loadView() {
        view = proposerView
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = "Dapp"
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            title: "Connect",
            style: .plain,
            target: self,
            action: #selector(connect)
        )
        
        proposerView.copyButton.addTarget(self, action: #selector(copyURI), for: .touchUpInside)
        proposerView.copyButton.isHidden = true
    }
    
    @objc
    private func connect() {
        // TODO: Propose pairing and get generated URI
        let uriString = "wc:8097df5f14871126866252c1b7479a14aefb980188fc35ec97d130d24bd887c8@2?controller=false&publicKey=19c5ecc857963976fabb98ed6a3e0a6ab6b0d65c018b6e25fbdcd3a164def868&relay=%7B%22protocol%22%3A%22waku%22%7D"
        currentURI = uriString
        DispatchQueue.global().async { [weak self] in
            if let qrImage = self?.generateQRCode(from: uriString) {
                DispatchQueue.main.async {
                    self?.proposerView.qrCodeView.image = qrImage
                    self?.proposerView.copyButton.isHidden = false
                }
            }
        }
    }
    
    @objc func copyURI() {
        UIPasteboard.general.string = currentURI
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
}
