

import Foundation
import UIKit
import WalletConnect
import WalletConnectUtils

class AccountRequestViewController: UIViewController, UITableViewDelegate, UITableViewDataSource  {
    private let session: Session
    private let client: WalletConnectClient = ClientDelegate.shared.client
    private let chainId: String
    private let account: String
    private let methods = ["eth_sendTransaction", "personal_sign", "eth_signTypedData"]
    private let accountRequestView = {
        AccountRequestView()
    }()
    
    init(session: Session, accountDetails: AccountDetails) {
        self.session = session
        self.chainId = accountDetails.chain
        self.account = accountDetails.account
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func loadView() {
        view = accountRequestView
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        accountRequestView.tableView.delegate = self
        accountRequestView.tableView.dataSource = self
        accountRequestView.iconView.image = UIImage(named: chainId)
        accountRequestView.chainLabel.text = chainId
        accountRequestView.accountLabel.text = account
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        methods.count
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return "Methods"
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "method_cell", for: indexPath)
        cell.textLabel?.text = methods[indexPath.row]
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let method = methods[indexPath.row]
        let requestParams = AnyCodable("")
        let request = Request(topic: session.topic, method: method, params: requestParams, chainId: chainId)
        client.request(params: request) { _ in }
        let alert = UIAlertController(title: "Request Sent", message: nil, preferredStyle: .alert)
        let action = UIAlertAction(title: "OK", style: .cancel)
        alert.addAction(action)
        present(alert, animated: true)
    }
}
