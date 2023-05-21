import SwiftUI
import WalletConnectNetworking
import WalletConnectPairing

public class Web3ModalSheetController: UIHostingController<AnyView> {
    
    @MainActor dynamic required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public init(projectId: String, metadata: AppMetadata, webSocketFactory: WebSocketFactory) {
        let view = AnyView(
            ModalContainerView(projectId: projectId, metadata: metadata, webSocketFactory: webSocketFactory)
        )
        
        super.init(rootView: view)
        self.modalTransitionStyle = .crossDissolve
        self.modalPresentationStyle = .overFullScreen
    }
    
    override public func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = .clear
    }
}
