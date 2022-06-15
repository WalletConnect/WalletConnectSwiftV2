import UIKit
import SwiftUI

protocol ProposalViewControllerDelegate: AnyObject {
    func didApproveSession()
    func didRejectSession()
}

final class ProposalViewController: UIHostingController<ProposalView> {

    weak var delegate: ProposalViewControllerDelegate?

    init(proposal: Proposal) {
        super.init(rootView: ProposalView(proposal: proposal))
        rootView.didPressApprove = { [weak self] in
            self?.approveSession()
        }
        rootView.didPressReject = { [weak self] in
            self?.rejectSession()
        }
    }

    private func approveSession() {
        delegate?.didApproveSession()
        dismiss(animated: true)
    }

    private func rejectSession() {
        delegate?.didRejectSession()
        dismiss(animated: true)
    }

    @MainActor required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
