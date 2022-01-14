import UIKit
import WalletConnect

final class SessionDetailsViewController: UIViewController {
        
    private let sessiondetailsView = {
        SessionDetailsView()
    }()
    private let sessionInfo: SessionInfo
    private let client: WalletConnectClient
    private let session: Session
    init(_ session: Session, _ client: WalletConnectClient) {
        self.sessionInfo = SessionInfo(name: session.peer.name ?? "",
                                           descriptionText: session.peer.description ?? "",
                                           dappURL: session.peer.description ?? "",
                                           iconURL: session.peer.icons?.first ?? "",
                                           chains: Array(session.permissions.blockchains),
                                           methods: Array(session.permissions.methods))
        self.client = client
        self.session = session
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        show(sessionInfo)
        super.viewDidLoad()
        sessiondetailsView.pingButton.addTarget(self, action: #selector(ping), for: .touchUpInside)
    }
    
    override func loadView() {
        view = sessiondetailsView
    }

    private func show(_ sessionInfo: SessionInfo) {
        sessiondetailsView.nameLabel.text = sessionInfo.name
        sessiondetailsView.descriptionLabel.text = sessionInfo.descriptionText
        sessiondetailsView.urlLabel.text = sessionInfo.dappURL
        sessiondetailsView.loadImage(at: sessionInfo.iconURL)
        sessiondetailsView.list(chains: sessionInfo.chains)
        sessiondetailsView.list(methods: sessionInfo.methods)
    }
    
    @objc
    private func ping() {
        client.ping(topic: session.topic) { result in
            switch result {
            case .success():
                print("received ping response")
            case .failure(let error):
                print(error)
            }
        }
    }
}


//class SessionDetailsViewControlle: UITableViewController {
//    
//    override func numberOfSections(in tableView: UITableView) -> Int {
//        return 3
//    }
//    
//    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
//        if section == 0 {
//            return "Chains"
//        } else if section == 1 {
//            return "Methods"
//        } else {
//            return "Pending Requests"
//        }
//    }
//}
