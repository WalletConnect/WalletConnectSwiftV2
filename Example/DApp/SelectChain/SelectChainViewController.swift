

import Foundation
import WalletConnect
import UIKit

struct Chain {
    let name: String
    let id: String
}

class SelectChainViewController: UIViewController, UITableViewDataSource {
    private let selectChainView: SelectChainView = {
        SelectChainView()
    }()
    let chains = [Chain(name: "Ethereum", id: "eip155:1"), Chain(name: "Polygon", id: "eip155:137")]
    let client = ClientDelegate.shared.client
    var onSessionSettled: ((Session)->())?
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = "Available Chains"
        selectChainView.tableView.dataSource = self
        selectChainView.connectButton.addTarget(self, action: #selector(connect), for: .touchUpInside)
        ClientDelegate.shared.onSessionSettled = { [unowned self] session in
            onSessionSettled?(session)
        }
    }
    
    override func loadView() {
        view = selectChainView
        

    }

    @objc
    private func connect() {
        print("[PROPOSER] Connecting to a pairing...")
        let methods: Set<String> = ["eth_sendTransaction", "personal_sign", "eth_signTypedData"]
        let blockchains: Set<Blockchain> = [Blockchain("eip155:1")!, Blockchain("eip155:137")!]
        let namespaces: Set<Namespace> = [Namespace(chains: blockchains, methods: methods, events: [])]
        Task {
            let uri = try await client.connect(namespaces: namespaces)
            showConnectScreen(uriString: uri!)
        }
    }
    
    private func showConnectScreen(uriString: String) {
        DispatchQueue.main.async { [unowned self] in
            let vc = UINavigationController(rootViewController: ConnectViewController(uri: uriString))
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
