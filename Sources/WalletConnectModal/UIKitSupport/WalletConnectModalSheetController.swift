import SwiftUI

#if canImport(UIKit)

class WalletConnectModalSheetController: UIHostingController<ModalContainerView> {
    
    @MainActor dynamic required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    init() {
        super.init(rootView: ModalContainerView())
        self.modalTransitionStyle = .crossDissolve
        self.modalPresentationStyle = .overFullScreen
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = .clear
    }
}

#elseif canImport(AppKit)

class WalletConnectModalSheetController: NSHostingController<ModalContainerView> {
    
    @MainActor dynamic required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    init() {
        super.init(rootView: ModalContainerView())
        // TODO:
//        self.modalTransitionStyle = .crossDissolve
//        self.modalPresentationStyle = .overFullScreen
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.wantsLayer = true
        self.view.layer?.backgroundColor = NSColor.clear.cgColor
    }
}

#endif
