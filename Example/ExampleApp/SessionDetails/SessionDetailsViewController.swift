import UIKit

final class SessionDetailsViewController: UIViewController {
        
    private let sessiondetailsView = {
        SessionDetailsView()
    }()
    private let sessionInfo: SessionInfo
    
    init(_ sessionInfo: SessionInfo) {
        self.sessionInfo = sessionInfo
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        show(sessionInfo)
        super.viewDidLoad()
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
}
