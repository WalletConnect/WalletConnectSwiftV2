import Foundation
import UIKit
import WalletConnectSign
import WalletConnectUtils

class AccountRequestViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    private let session: Session
    private let chainId: String
    private let account: String
    private let methods: [String]
    private let accountRequestView = {
        AccountRequestView()
    }()

    init(session: Session, accountDetails: AccountDetails) {
        self.session = session
        self.chainId = accountDetails.chain
        self.account = accountDetails.account
        self.methods = accountDetails.methods
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
        return methods.count
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
        let requestParams = getRequest(for: method)

        let request = Request(topic: session.topic, method: method, params: requestParams, chainId: Blockchain(chainId)!)
        Task {
            do {
                try await Sign.instance.request(params: request)
                DispatchQueue.main.async { [weak self] in
                    self?.openWallet()
                }
            } catch {
                print(error)
                // show failure alert
            }
        }
    }
    
    private func openWallet() {
        UIApplication.shared.open(URL(string: "walletapp://wc?requestSent")!)
    }

    private func presentConfirmationAlert() {
        let alert = UIAlertController(title: "Request Sent", message: nil, preferredStyle: .alert)
        let action = UIAlertAction(title: "OK", style: .cancel)
        alert.addAction(action)
        present(alert, animated: true)
    }

    private func getRequest(for method: String) -> AnyCodable {
        let account = session.namespaces.first!.value.accounts.first!.absoluteString
        if method == "eth_sendTransaction" {
            let tx = Stub.tx
            return AnyCodable(tx)
        } else if method == "personal_sign" {
            return AnyCodable(["0x4d7920656d61696c206973206a6f686e40646f652e636f6d202d2031363533333933373535313531", account])
        } else if method == "eth_signTypedData" {
            return AnyCodable([account, Stub.eth_signTypedData])
        }
        fatalError("not implemented")
    }
}

struct Transaction: Codable {
    let from, to, data, gas: String
    let gasPrice, value, nonce: String
}

private enum Stub {
    static let tx = [Transaction(from: "0x9b2055d370f73ec7d8a03e965129118dc8f5bf83",
                                to: "0x9b2055d370f73ec7d8a03e965129118dc8f5bf83",
                                data: "0xd46e8dd67c5d32be8d46e8dd67c5d32be8058bb8eb970870f072445675058bb8eb970870f072445675",
                                gas: "0x76c0",
                                gasPrice: "0x9184e72a000",
                                value: "0x9184e72a",
                                nonce: "0x117")]
    static let eth_signTypedData = """
{
"types": {
    "EIP712Domain": [
        {
            "name": "name",
            "type": "string"
        },
        {
            "name": "version",
            "type": "string"
        },
        {
            "name": "chainId",
            "type": "uint256"
        },
        {
            "name": "verifyingContract",
            "type": "address"
        }
    ],
    "Person": [
        {
            "name": "name",
            "type": "string"
        },
        {
            "name": "wallet",
            "type": "address"
        }
    ],
    "Mail": [
        {
            "name": "from",
            "type": "Person"
        },
        {
            "name": "to",
            "type": "Person"
        },
        {
            "name": "contents",
            "type": "string"
        }
    ]
},
"primaryType": "Mail",
"domain": {
    "name": "Ether Mail",
    "version": "1",
    "chainId": 1,
    "verifyingContract": "0xCcCCccccCCCCcCCCCCCcCcCccCcCCCcCcccccccC"
},
"message": {
    "from": {
        "name": "Cow",
        "wallet": "0xCD2a3d9F938E13CD947Ec05AbC7FE734Df8DD826"
    },
    "to": {
        "name": "Bob",
        "wallet": "0xbBbBBBBbbBBBbbbBbbBbbbbBBbBbbbbBbBbbBBbB"
    },
    "contents": "Hello, Bob!"
}
}
"""
}
