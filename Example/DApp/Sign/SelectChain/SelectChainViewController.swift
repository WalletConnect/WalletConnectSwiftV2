import Foundation
import WalletConnectSign
import WalletConnectPairing
import UIKit
import Combine

struct Chain {
    let name: String
    let id: String
}

class SelectChainViewController: UIViewController, UITableViewDataSource {
    private let selectChainView: SelectChainView = {
        SelectChainView()
    }()
    private var publishers = [AnyCancellable]()

    let chains = [
        Chain(name: "Ethereum", id: "eip155:1"),
        Chain(name: "Polygon", id: "eip155:137"),
        Chain(name: "Solana", id: "solana:4sGjMW1sUnHzSxGspuhpqLDx6wiyjNtZ")
    ]

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = "Available Chains"
        selectChainView.tableView.dataSource = self
        selectChainView.connectButton.addTarget(self, action: #selector(connect), for: .touchUpInside)
        selectChainView.openWallet.addTarget(self, action: #selector(openWallet), for: .touchUpInside)
    }

    override func loadView() {
        view = selectChainView
    }

    @objc
    private func connect() {
        print("[PROPOSER] Connecting to a pairing...")
        let namespaces: [String: ProposalNamespace] = [
            "eip155": ProposalNamespace(
                chains: [
                    Blockchain("eip155:137")!
                ],
                methods: [
                    "eth_sendTransaction",
                    "personal_sign",
                    "eth_signTypedData"
                ], events: []
            ),
            "eip155:1": ProposalNamespace(
                methods: [
                    "eth_sendTransaction",
                    "personal_sign",
                    "eth_signTypedData"
                ],
                events: []
            )
        ]
        let optionalNamespaces: [String: ProposalNamespace] = [
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
        let sessionProperties: [String: String] = [
            "caip154-mandatory": "true"
        ]
        Task {
            let uri = try await Pair.instance.create()
            try await Sign.instance.connect(
                requiredNamespaces: namespaces,
                optionalNamespaces: optionalNamespaces,
                sessionProperties: sessionProperties,
                topic: uri.topic
            )
            showConnectScreen(uri: uri)
        }
    }

    @objc
    private func openWallet() {
        UIApplication.shared.open(URL(string: "walletconnectwallet://")!)
    }

    private func showConnectScreen(uri: WalletConnectURI) {
        DispatchQueue.main.async { [unowned self] in
            let vc = UINavigationController(rootViewController: ConnectViewController(uri: uri))
            present(vc, animated: true, completion: nil)
        }
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        chains.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "chain_cell", for: indexPath)
        let chain = chains[indexPath.row]
        cell.textLabel?.text = chain.name
        cell.imageView?.image = UIImage(named: chain.id)
        cell.selectionStyle = .none
        return cell
    }
}
