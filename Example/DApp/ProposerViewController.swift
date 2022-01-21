import UIKit
import WalletConnect
struct AccountDetails {
    let chain: String
    let methods: [String]
    let account: String
}
final class ProposerViewController: UIViewController {
    
    let client = ClientDelegate.shared.client
    let session: Session
    var activeItems: [AccountDetails] = []
    
    private let proposerView: ProposerView = {
        ProposerView()
    }()
    
    init(session: Session) {
        self.session = session
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func loadView() {
        view = proposerView
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = "Accounts"
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            title: "Disconnect",
            style: .plain,
            target: self,
            action: #selector(disconnect)
        )
        proposerView.tableView.dataSource = self
        proposerView.tableView.delegate = self
        client.logger.setLogging(level: .debug)
        session.
    }
    
    @objc
    private func disconnect() {
        client.disconnect(topic: session.topic, reason: Reason(code: 0, message: "disconnect"))
    }
}

extension ProposerViewController: UITableViewDataSource, UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        activeItems.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "pairingCell", for: indexPath) as! ActivePairingCell
        cell.item = activeItems[indexPath.row]
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    }
}
