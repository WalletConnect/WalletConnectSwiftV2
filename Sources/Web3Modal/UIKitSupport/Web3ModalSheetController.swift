import SwiftUI

@available(iOS 14.0, *)
public class Web3ModalSheetController: UIHostingController<ModalContainerView> {
    
    @MainActor dynamic required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public init() {
        super.init(rootView: ModalContainerView())
        self.modalTransitionStyle = .crossDissolve
        self.modalPresentationStyle = .overFullScreen
    }
    
    override public func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = .clear
    }
}
