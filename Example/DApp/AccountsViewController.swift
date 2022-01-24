import UIKit
import WalletConnect
struct AccountDetails {
    let chain: String
    let methods: [String]
    let account: String
}
final class AccountsViewController: UIViewController, UITableViewDataSource, UITableViewDelegate  {
    
    let client = ClientDelegate.shared.client
    let session: Session
    var accountsDetails: [AccountDetails] = []
    var onDisconnect: (()->())?
    
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
        session.permissions.blockchains.forEach { chain in
            session.accounts.forEach { account in
                accountsDetails.append(AccountDetails(chain: chain, methods: Array(session.permissions.methods), account: account))
            }
        }
    }
    
    @objc
    private func disconnect() {
        client.disconnect(topic: session.topic, reason: Reason(code: 0, message: "disconnect"))
        onDisconnect?()
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        accountsDetails.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "accountCell", for: indexPath)
        let details = accountsDetails[indexPath.row]
        cell.textLabel?.text = details.account
        cell.imageView?.image = UIImage(named: details.chain)
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        showAccountRequestScreen()
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 70
    }
    
    func showAccountRequestScreen() {
        let vc = AccountRequestViewController()
        navigationController?.pushViewController(vc, animated: true)
    }
    
}
