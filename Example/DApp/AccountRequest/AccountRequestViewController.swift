

import Foundation
import UIKit
import WalletConnect

class AccountRequestViewController: UIViewController, UITableViewDelegate, UITableViewDataSource  {
    private let session: Session
    private let client: WalletConnectClient = ClientDelegate.shared.client
    private let chainId: String
    private let account: String
    private let methods = ["eth_sendTransaction", "personal_sign", "eth_signTypedData"]
    private let accountRequestView = {
        AccountRequestView()
    }()
    
    init(_ session: Session, chainId: String, account: String) {
        self.session = session
        self.chainId = chainId
        self.account = account
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
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        methods.count
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return "Methods"
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        cell.textLabel?.text = methods[indexPath.row]
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let method = methods[indexPath.row]
        let requestParams = AnyCodable("")
        let request = Request(topic: session.topic, method: method, params: params, chainId: chainId)
        client.request(params: request) { _ in }
    }
}
