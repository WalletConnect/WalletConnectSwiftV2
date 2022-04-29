import UIKit

protocol ProposalViewControllerDelegate: AnyObject {
    func didApproveSession()
    func didRejectSession()
}

final class ProposalViewController: UIViewController {
    
    weak var delegate: ProposalViewControllerDelegate?
    
    private let sessionView = {
        ProposalView()
    }()
    
    override func loadView() {
        view = sessionView
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        sessionView.approveButton.addTarget(self, action: #selector(approveSession), for: .touchUpInside)
        sessionView.rejectButton.addTarget(self, action: #selector(rejectSession), for: .touchUpInside)
    }
    
    func show(_ sessionInfo: SessionInfo) {
        sessionView.nameLabel.text = sessionInfo.name
        sessionView.descriptionLabel.text = sessionInfo.descriptionText
        sessionView.urlLabel.text = sessionInfo.dappURL
        sessionView.loadImage(at: sessionInfo.iconURL)
        sessionView.list(chains: sessionInfo.chains)
        sessionView.list(methods: sessionInfo.methods)
    }
    
    @objc
    private func approveSession() {
        delegate?.didApproveSession()
        dismiss(animated: true)
    }
    
    @objc
    private func rejectSession() {
        delegate?.didRejectSession()
        dismiss(animated: true)
    }
}
