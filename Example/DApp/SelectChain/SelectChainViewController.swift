

import Foundation
import WalletConnectAuth
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

    let chains = [Chain(name: "Ethereum", id: "eip155:1"), Chain(name: "Polygon", id: "eip155:137")]
    var onSessionSettled: ((Session)->())?
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = "Available Chains"
        selectChainView.tableView.dataSource = self
        selectChainView.connectButton.addTarget(self, action: #selector(connect), for: .touchUpInside)
        Auth.instance.sessionSettlePublisher.sink {[unowned self] session in
            onSessionSettled?(session)
        }.store(in: &publishers)
    }
    
    override func loadView() {
        view = selectChainView
        

    }

    @objc
    private func connect() {
        print("[PROPOSER] Connecting to a pairing...")
        let methods: Set<String> = ["eth_sendTransaction", "personal_sign", "eth_signTypedData"]
        let blockchains: Set<Blockchain> = [Blockchain("eip155:1")!, Blockchain("eip155:137")!]
        let namespaces: [String: ProposalNamespace] = ["eip155": ProposalNamespace(chains: blockchains, methods: methods, events: [], extension: nil)]
        Task {
            let uri = try await Auth.instance.connect(requiredNamespaces: namespaces)
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
