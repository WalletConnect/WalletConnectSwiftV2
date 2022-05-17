
import Foundation
import UIKit
import WalletConnectAuth
import Web3

class RequestViewController: UIViewController {
    var onSign: (()->())?
    var onReject: (()->())?
    let sessionRequest: Request
    private let requestView = RequestView()

    init(_ sessionRequest: Request) {
        self.sessionRequest = sessionRequest
        super.init(nibName: nil, bundle: nil)
    }
    
    override func loadView() {
        view = requestView
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        requestView.approveButton.addTarget(self, action: #selector(signAction), for: .touchUpInside)
        requestView.rejectButton.addTarget(self, action: #selector(rejectAction), for: .touchUpInside)
        requestView.nameLabel.text = sessionRequest.method
        requestView.descriptionLabel.text = getParamsDescription()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc
    private func signAction() {
        onSign?()
        dismiss(animated: true)
    }
    
    @objc
    private func rejectAction() {
        onReject?()
        dismiss(animated: true)
    }
    
    private func getParamsDescription() -> String {
        let method = sessionRequest.method
        if method == "personal_sign" {
            return try! sessionRequest.params.get([String].self).description
        } else if method == "eth_signTypedData" {
            return try! sessionRequest.params.get([String].self).description
        } else if method == "eth_sendTransaction" {
            let params = try! sessionRequest.params.get([EthereumTransaction].self)
            return params[0].description
        }
        fatalError("not implemented")
    }
}
