import UIKit

final class SessionViewController: UIViewController {
    
    private let sessionView = {
        SessionView()
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
    }
    
    @objc
    private func approveSession() {
        print("approve")
    }
    
    @objc
    private func rejectSession() {
        print("reject")
    }
}
