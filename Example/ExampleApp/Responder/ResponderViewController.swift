import UIKit
import WalletConnect

final class ResponderViewController: UIViewController {

    let client: WalletConnectClient = {
        let options = WalletClientOptions(
            apiKey: "",
            name: "Example",
            isController: true,
            metadata: AppMetadata(name: "Example App", description: nil, url: nil, icons: nil),
            relayURL: URL(string: "wss://staging.walletconnect.org")!)
        return WalletConnectClient(options: options)
    }()
    
    var sessionItems: [ActiveSessionItem] = []
    
    private let responderView: ResponderView = {
        ResponderView()
    }()
    
    override func loadView() {
        view = responderView
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = "Wallet"
        
        responderView.scanButton.addTarget(self, action: #selector(showScanner), for: .touchUpInside)
        responderView.pasteButton.addTarget(self, action: #selector(showTextInput), for: .touchUpInside)
        
        responderView.tableView.dataSource = self
        responderView.tableView.delegate = self
        sessionItems = ActiveSessionItem.mockList()
    }
    
    @objc
    private func showScanner() {
        let scannerViewController = ScannerViewController()
        scannerViewController.delegate = self
        present(scannerViewController, animated: true)
    }
    
    @objc
    private func showTextInput() {
        let alert = UIAlertController.createInputAlert { [weak self] inputText in
            self?.pairClient(uri: inputText)
        }
        present(alert, animated: true)
    }
    
    private func showSessionProposal() {
        let proposalViewController = SessionViewController()
        proposalViewController.delegate = self
        proposalViewController.show(SessionInfo.mock())
        present(proposalViewController, animated: true)
    }
    
    private func pairClient(uri: String) {
        print("connecting to: \(uri)")
    }
}

extension ResponderViewController: UITableViewDataSource, UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        sessionItems.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "sessionCell", for: indexPath) as! ActiveSessionCell
        cell.item = sessionItems[indexPath.row]
        return cell
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            sessionItems.remove(at: indexPath.row)
            tableView.deleteRows(at: [indexPath], with: .automatic)
        }
    }
    
    func tableView(_ tableView: UITableView, titleForDeleteConfirmationButtonForRowAt indexPath: IndexPath) -> String? {
        "Disconnect"
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        print("did select row \(indexPath)")
    }
}

extension ResponderViewController: ScannerViewControllerDelegate {
    
    func didScan(_ code: String) {
        pairClient(uri: code)
    }
}

extension ResponderViewController: SessionViewControllerDelegate {
    
    func didApproveSession() {
        print("did approve session")
    }
    
    func didRejectSession() {
        print("did reject session")
    }
}

extension UIAlertController {
    
    static func createInputAlert(confirmHandler: @escaping (String) -> Void) -> UIAlertController {
        let alert = UIAlertController(title: "Paste URI", message: "Enter a WalletConnect URI to connect.", preferredStyle: .alert)
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
        let confirmAction = UIAlertAction(title: "Connect", style: .default) { _ in
            if let input = alert.textFields?.first?.text, !input.isEmpty {
                confirmHandler(input)
            }
        }
        alert.addTextField { textField in
            textField.placeholder = "wc://a14aefb980188fc35ec9..."
        }
        alert.addAction(cancelAction)
        alert.addAction(confirmAction)
        alert.preferredAction = confirmAction
        return alert
    }
}
