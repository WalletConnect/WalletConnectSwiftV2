import Foundation
import UIKit
import WalletConnectSign
import WalletConnectPairing

class ConnectViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    let uri: WalletConnectURI
    let activePairings: [Pairing] = Pair.instance.getPairings()
    let segmentedControl = UISegmentedControl(items: ["Pairings", "New Pairing"])

    init(uri: WalletConnectURI) {
        self.uri = uri
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
            let qrImage = QRCodeGenerator.generateQRCode(from: uri.absoluteString)
            DispatchQueue.main.async { [self] in
                self.connectView.qrCodeView.image = qrImage
                self.connectView.copyButton.isHidden = false
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
        UIPasteboard.general.string = uri.absoluteString
    }

    @objc func connectWithExampleWallet() {
        let url = URL(string: "https://walletconnect.com/wc?uri=\(uri.absoluteString)")!
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
        let namespaces: [String: ProposalNamespace] = [
            "eip155": ProposalNamespace(
                chains: [
                    Blockchain("eip155:1")!,
                    Blockchain("eip155:137")!
                ],
                methods: [
                    "eth_sendTransaction",
                    "personal_sign",
                    "eth_signTypedData"
                ], events: []
            ),
            "solana": ProposalNamespace(
                chains: [
                    Blockchain("solana:4sGjMW1sUnHzSxGspuhpqLDx6wiyjNtZ")!
                ],
                methods: [
                    "solana_signMessage",
                    "solana_signTransaction"
                ], events: []
            )
        ]
        Task {
            _ = try await Sign.instance.connect(requiredNamespaces: namespaces, topic: pairingTopic)
            connectWithExampleWallet()
        }
    }
}
