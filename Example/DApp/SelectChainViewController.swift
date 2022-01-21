

import Foundation
import WalletConnect
import UIKit

class SelectChainViewController: UIViewController {
    private let selectChainView: SelectChainView = {
        SelectChainView()
    }()
    let client = ClientDelegate.shared.client
    var onSessionSettled: ((Session)->())?
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = "Select Chain"
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
        let permissions = Session.Permissions(
            blockchains: ["a chain"],
            methods: ["a method"],
            notifications: []
        )
        do {
            if let uri = try client.connect(sessionPermissions: permissions) {
                showConnectScreen(uriString: uri)
            }
        } catch {
            print("[PROPOSER] Pairing connect error: \(error)")
        }
    }
    
    private func showConnectScreen(uriString: String) {
        DispatchQueue.main.async { [unowned self] in
            let vc = ConnectViewController(uri: uriString)
            present(vc, animated: true, completion: nil)
        }
    }
}


class SelectChainView: UIView {
    let tableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .insetGrouped)
        tableView.backgroundColor = .tertiarySystemBackground
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "chain")
        return tableView
    }()
    let connectButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Connect", for: .normal)
        button.backgroundColor = .systemBlue
        button.tintColor = .white
        button.layer.cornerRadius = 8
        return button
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .systemBackground
        addSubview(tableView)
        addSubview(connectButton)

        subviews.forEach { $0.translatesAutoresizingMaskIntoConstraints = false }
        
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor, constant: 16),
            tableView.leadingAnchor.constraint(equalTo: leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: safeAreaLayoutGuide.bottomAnchor),
            
            connectButton.bottomAnchor.constraint(equalTo: safeAreaLayoutGuide.bottomAnchor, constant: -16),
            connectButton.centerXAnchor.constraint(equalTo: safeAreaLayoutGuide.centerXAnchor),
            connectButton.heightAnchor.constraint(equalToConstant: 44),
            connectButton.widthAnchor.constraint(equalToConstant: 120),
        ])
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
