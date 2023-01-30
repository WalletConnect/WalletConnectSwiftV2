import UIKit
import WalletConnectSign
import WalletConnectPush
import Combine

struct AccountDetails {
    let chain: String
    let methods: [String]
    let account: String
}

final class AccountsViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {

    let session: Session
    var accountsDetails: [AccountDetails] = []
    var onDisconnect: (() -> Void)?
    var pushSubscription: PushSubscription?

    private var publishers = [AnyCancellable]()
    private let accountsView: AccountsView = {
        AccountsView()
    }()

    init(session: Session) {
        self.session = session
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func loadView() {
        view = accountsView
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

        navigationItem.leftBarButtonItem = UIBarButtonItem(
            title: "Push Test",
            style: .plain,
            target: self,
            action: #selector(pushTest)
        )

        accountsView.tableView.dataSource = self
        accountsView.tableView.delegate = self
        session.namespaces.values.forEach { namespace in
            namespace.accounts.forEach { account in
                accountsDetails.append(AccountDetails(chain: account.blockchainIdentifier, methods: Array(namespace.methods), account: account.address)) // TODO: Rethink how this info is displayed on example
            }
        }
    }

    func proposePushSubscription() {
        let account = session.namespaces.values.first!.accounts.first!

        Task(priority: .high){ try! await Push.dapp.request(account: account, topic: session.pairingTopic)}
        Push.dapp.responsePublisher.sink { (id: RPCID, result: Result<PushSubscription, PushError>) in
            switch result {
            case .success(let subscription):
                self.pushSubscription = subscription
            case .failure(let error):
                print(error)
            }
        }.store(in: &publishers)
    }

    @objc
    private func pushTest() {
        guard let pushTopic = pushSubscription?.topic else {return}
        let message = PushMessage(title: "Push Message", body: "He,y this is a message from the swift client", icon: "", url: "")
        Task(priority: .userInitiated) { try! await Push.dapp.notify(topic: pushTopic, message: message) }
    }

    @objc
    private func disconnect() {
        Task {
            do {
                try await Sign.instance.disconnect(topic: session.topic)
                DispatchQueue.main.async { [weak self] in
                    self?.onDisconnect?()
                }
            } catch {
                print(error)
                // show failure alert
            }
        }
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        accountsDetails.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "accountCell", for: indexPath)
        let details = accountsDetails[indexPath.row]
        cell.textLabel?.text = details.account
        cell.imageView?.image = UIImage(named: details.chain)
        cell.textLabel?.numberOfLines = 0
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        showAccountRequestScreen(accountsDetails[indexPath.row])
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 70
    }

    func showAccountRequestScreen(_ details: AccountDetails) {
        let vc = AccountRequestViewController(session: session, accountDetails: details)
        navigationController?.pushViewController(vc, animated: true)
    }

}
