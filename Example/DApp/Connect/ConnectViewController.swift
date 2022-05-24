
import Foundation
import UIKit
import WalletConnectSign

class ConnectViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    let uriString: String
    let activePairings: [Pairing] = Sign.instance.getSettledPairings()
    let segmentedControl = UISegmentedControl(items: ["Pairings", "New Pairing"])

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
        connectView.tableView.dataSource = self
        connectView.tableView.delegate = self
        connectView.copyButton.isHidden = true
        setUpSegmentedControl()
    }
    
    func setUpSegmentedControl() {
        segmentedControl.selectedSegmentIndex = 0
        self.navigationItem.titleView = segmentedControl
        segmentedControl.addTarget(self, action: #selector(segmentAction), for: .valueChanged)
    }
    
    @objc func segmentAction() {
        if segmentedControl.selectedSegmentIndex == 0 {
            connectView.tableView.isHidden = false
        } else {
            connectView.tableView.isHidden = true
        }
    }
    
    @objc func copyURI() {
        UIPasteboard.general.string = uriString
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
    
    @objc func connectWithExampleWallet() {
        let url = URL(string: "https://walletconnect.com/wc?uri=\(uriString)")!
        DispatchQueue.main.async {
            UIApplication.shared.open(url, options: [:]) { [weak self] _ in
                self?.dismiss(animated: true, completion: nil)
            }
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        activePairings.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "pairing_cell", for: indexPath)
        cell.textLabel?.text = activePairings[indexPath.row].peer?.name ?? ""
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let pairingTopic = activePairings[indexPath.row].topic
        let blockchains: Set<Blockchain> = [Blockchain("eip155:1")!, Blockchain("eip155:137")!]
        let methods: Set<String> = ["eth_sendTransaction", "personal_sign", "eth_signTypedData"]
        let namespaces: [String: ProposalNamespace] = ["eip155": ProposalNamespace(chains: blockchains, methods: methods, events: [], extensions: nil)]
        Task {
            _ = try await Sign.instance.connect(requiredNamespaces: namespaces, topic: pairingTopic)
            connectWithExampleWallet()
        }
    }
}
